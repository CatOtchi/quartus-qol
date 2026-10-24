"""Short-lived offline slang/Verible worker, started automatically by Quartus."""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import zlib



def run_tool(command, **kwargs):
    # Quartus prepends old runtime/debug DLLs to PATH and sets a DLL directory.
    # Let these independent tools load the Windows runtimes they normally use.
    env = os.environ.copy()
    windows = env.get('SystemRoot', r'C:\Windows')
    env['PATH'] = os.pathsep.join([str(Path(command[0]).parent),
                                 str(Path(windows) / 'System32'), windows])
    return subprocess.run(command, env=env, stdin=subprocess.DEVNULL,
                          capture_output=True,
                          creationflags=subprocess.CREATE_NO_WINDOW, **kwargs)


def token(value):
    if isinstance(value, (list, tuple)):
        value = ' '.join(token(v) for v in value)
    value = str(value)
    for a, b in [('\\', '\\\\'), ('"', '\\"'), ('\n', '\\n'),
                 ('\r', '\\r'), ('\t', '\\t'), ('$', '\\$'),
                 ('[', '\\['), (']', '\\]')]:
        value = value.replace(a, b)
    return '"' + value + '"'


def emit(**fields):
    print(' '.join(token(v) for pair in fields.items() for v in pair), flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['format', 'lint'])
    parser.add_argument('request')
    args = parser.parse_args()
    request = json.loads(Path(args.request).read_text(encoding="utf-8"))
    path = Path(request['path']).resolve()
    original_bytes = path.read_bytes()
    original = original_bytes.decode('utf-8-sig')
    # Quartus keeps UTF-8 source bytes in its Scintilla buffer.
    if args.mode == 'format':
        tool_args = request.get('format_args', [])
        run = run_tool([request['verible'], *tool_args, str(path)], timeout=15)
        if run.returncode:
            # Incomplete syntax is normal while editing: keep original code.
            emit(status='format_skipped', path=path.as_posix(),
                 detail=f'exit={run.returncode}; ' + run.stderr.decode('utf-8', errors='replace')[:2000])
            return
        formatted = run.stdout.decode('utf-8').replace('\r\n', '\n')
        if b'\r\n' in original_bytes:
            formatted = formatted.replace('\n', '\r\n')
        emit(status='formatted', path=path.as_posix(), original=original,
             formatted=formatted)
        return

    files = [Path(p).resolve() for p in request['sources']]
    snapshots = [(p.as_posix(), zlib.crc32(p.read_bytes())) for p in files]
    slang_args = request.get('slang_args', [])
    for inc in request.get('include_dirs', []):
        slang_args += ['-I', inc]
    for macro in request.get('defines', []):
        slang_args += ['-D', macro]
    if request.get('top'):
        slang_args += ['--top', request['top']]
    with tempfile.TemporaryDirectory(prefix='quartus-qol-') as temp:
        diagnostic_file = Path(temp) / 'diagnostics.json'
        run = run_tool([request['slang'], *slang_args,
                              '--diag-json', str(diagnostic_file),
                              '--error-limit', '40', *map(str, files)],
                             cwd=request['root'], timeout=30)
        if not diagnostic_file.exists():
            raise RuntimeError(run.stderr.decode('utf-8', errors='replace') or
                               run.stdout.decode('utf-8', errors='replace'))
        diagnostics = json.loads(diagnostic_file.read_text(encoding='utf-8'))
    if any(zlib.crc32(Path(p).read_bytes()) != crc for p, crc in snapshots):
        emit(status='stale', path=path.as_posix())
        return
    rows = []
    for diag in diagnostics:
        match = re.match(r'^(.*):(\d+):(\d+)$', diag.get('location', ''))
        if not match:
            continue
        name, line, column = match.groups()
        name = Path(name)
        if not name.is_absolute():
            name = Path(request['root']) / name
        name = name.resolve()
        severity = diag.get('severity', 'error')
        if severity not in ('error', 'fatal', 'warning', 'note', 'info', 'information', 'remark'):
            continue
        if severity in ('note', 'info', 'information', 'remark'):
            severity = 'information'
        line, column = int(line), int(column)
        message = diag.get('message', '')
        length = 1
        try:
            source_line = name.read_text(encoding='utf-8-sig').splitlines()[line - 1]
            # Underline the token named by slang, or the identifier at its location.
            text = source_line.encode('utf-8')[column - 1:].decode('utf-8', errors='ignore')
            tok = re.match(r'[A-Za-z_$][A-Za-z0-9_$]*', text)
            if tok:
                length = len(tok.group().encode('utf-8'))
        except (OSError, IndexError):
            pass
        rows.append([name.as_posix(), line, column, length, severity,
                     f'slang: {message}'])
    emit(status='diagnostics', path=path.as_posix(), diagnostics=rows,
         snapshots=snapshots)


if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        emit(status='failure', detail=f'{type(exc).__name__}: {exc}')
