# Audita a frost-final: para cada commit, lista metodos/constantes/ivars usados que so sao definidos em commits POSTERIORES.
# Heuristica textual: pode haver falsos positivos (ex.: variavel local com nome igual a um metodo). Uso: python3 scripts/audit_commit_order.py
import re
import subprocess
import sys
from collections import defaultdict

BASE = '1999204ea'
TOP = 'frost-final'
FIRST_AUDIT_POS = 5
GAME_DIR = 'lib/engine/game/g_frost1831'
VIEW_DIR = 'assets/app/view/game/g_frost1831'


def git(*args):
    return subprocess.run(['git', *args], capture_output=True, text=True, errors='replace').stdout


commits = git('log', '--reverse', '--format=%H %s', f'{BASE}..{TOP}').strip().split('\n')
commits = [c.split(' ', 1) for c in commits]
pos_of = {sha: i + 1 for i, (sha, _) in enumerate(commits)}
subj = {sha: s for sha, s in commits}

DEF_RE = re.compile(r'\bdef\s+(?:self\.)?([a-z_][A-Za-z0-9_]*[?!=]?)')
ATTR_RE = re.compile(r'\battr_(?:reader|accessor|writer)\s+(.*)')
CONST_RE = re.compile(r'^\s*([A-Z][A-Z0-9_]+)\s*=')
IVAR_RE = re.compile(r'(@[a-z_][a-z0-9_]*)\s*(?:\|\||&&|\+|-)?=(?!=)')


def definitions(rev, paths):
    methods, consts, ivars = set(), set(), set()
    out = git('grep', '-h', '-I', '-E', r'def |attr_|^\s*[A-Z][A-Z0-9_]+\s*=|@[a-z_0-9]+\s*(\|\||&&|\+|-)?=', rev, '--', *paths)
    for line in out.split('\n'):
        for m in DEF_RE.finditer(line):
            methods.add(m.group(1).rstrip('='))
        m = ATTR_RE.search(line)
        if m:
            methods.update(re.findall(r':([a-z_][A-Za-z0-9_]*)', m.group(1)))
            for n in re.findall(r':([a-z_][A-Za-z0-9_]*)', m.group(1)):
                ivars.add('@' + n)
        m = CONST_RE.match(line)
        if m:
            consts.add(m.group(1))
        for m in IVAR_RE.finditer(line):
            ivars.add(m.group(1))
    return methods, consts, ivars


def strip_code(line):
    line = re.sub(r"'(?:[^'\\]|\\.)*'", "''", line)
    line = re.sub(r'"(?:[^"\\]|\\.)*"', '""', line)
    return line.split(' #')[0] if not line.lstrip().startswith('#') else ''


ALL_PATHS = ['lib', 'assets']
base_m, base_c, base_i = definitions(BASE, ALL_PATHS)
top_m, top_c, top_i = definitions(TOP, ALL_PATHS)
frost_top_m, frost_top_c, frost_top_i = definitions(TOP, [GAME_DIR, VIEW_DIR])

candidates_m = (top_m - base_m)
candidates_c = (top_c - base_c)
candidates_i = {i for i in frost_top_i}

defs_at = {}
for sha, _ in commits:
    defs_at[sha] = definitions(sha, ALL_PATHS)


def first_defined(kind, name):
    idx = {'m': 0, 'c': 1, 'i': 2}[kind]
    for sha, _ in commits:
        if name in defs_at[sha][idx]:
            return pos_of[sha]
    return None


findings = defaultdict(list)
for sha, _ in commits:
    pos = pos_of[sha]
    if pos < FIRST_AUDIT_POS or 'DO NOT UPSTREAM' in subj[sha]:
        continue
    diff = git('diff', '-U0', f'{sha}^', sha, '--', GAME_DIR, VIEW_DIR)
    m_at, c_at, i_at = defs_at[sha]
    seen = set()
    for line in diff.split('\n'):
        if not line.startswith('+') or line.startswith('+++'):
            continue
        code = strip_code(line[1:])
        if not code.strip() or re.match(r'\s*def\s', code):
            code_for_calls = re.sub(r'\bdef\s+\S+', '', code)
        else:
            code_for_calls = code
        for name in re.findall(r'(?<![@:\w$])([a-z_][a-z0-9_]*[?!]?)(?![\w:])', code_for_calls):
            if name in candidates_m and name not in m_at and ('m', name) not in seen:
                seen.add(('m', name))
                findings[pos].append(('metodo', name, first_defined('m', name)))
        for name in re.findall(r'\b([A-Z][A-Z0-9_]{2,})\b', code):
            if name in candidates_c and name not in c_at and ('c', name) not in seen:
                seen.add(('c', name))
                findings[pos].append(('constante', name, first_defined('c', name)))
        if '/g_frost1831/' in diff or True:
            for name in re.findall(r'(@[a-z_][a-z0-9_]*)', code):
                if name in candidates_i and name not in i_at and ('i', name) not in seen:
                    seen.add(('i', name))
                    findings[pos].append(('ivar', name, first_defined('i', name)))

for pos in sorted(findings):
    sha = commits[pos - 1][0]
    print(f'#{pos} {subj[sha]}')
    for kind, name, later in sorted(findings[pos], key=lambda x: (x[2] or 999, x[1])):
        where = f'#{later}' if later else 'nunca'
        print(f'    {kind:9} {name:45} definido em {where}')
print('commits auditados:', len([p for p in pos_of.values() if p >= FIRST_AUDIT_POS]))
