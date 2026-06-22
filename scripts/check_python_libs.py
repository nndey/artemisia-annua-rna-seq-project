import sys
packages = {
    'pandas': 'pd',
    'numpy': 'np',
    'matplotlib': 'mpl',
    'seaborn': 'sns'
}
for pkg, alias in packages.items():
    try:
        __import__(pkg)
        version = getattr(sys.modules[pkg], '__version__', 'unknown')
        print(f'{pkg:<20} {version}')
    except ImportError:
        print(f'{pkg:<20} NOT FOUND')