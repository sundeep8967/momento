import re

with open('lib/router/app_router.dart', 'r') as f:
    content = f.read()

# 1. Add _fluidRoute definition below _fadeRoute
fluid_route_def = """
CustomTransitionPage<void> _fluidRoute(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOutCirc).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}
"""

if '_fluidRoute' not in content:
    content = content.replace('final GoRouter appRouter = GoRouter(', fluid_route_def + '\nfinal GoRouter appRouter = GoRouter(')

# 2. Replace simple builders: builder: (context, state) => X,
content = re.sub(
    r'builder:\s*\(\s*context\s*,\s*state\s*\)\s*=>\s*(.+?),',
    r'pageBuilder: (context, state) => _fluidRoute(state, \1),',
    content
)

# 3. Replace block builders: builder: (context, state) { ... return X; },
def block_replacer(match):
    body = match.group(1)
    # find the return statement inside the body
    body = re.sub(r'return\s+(.+?);', r'return _fluidRoute(state, \1);', body)
    return f'pageBuilder: (context, state) {{{body}}},'

content = re.sub(
    r'builder:\s*\(\s*context\s*,\s*state\s*\)\s*\{(.+?)\},',
    block_replacer,
    content,
    flags=re.DOTALL
)

# Exception: We don't want to replace builder: (context, state, child) for ShellRoute, which the regex didn't match anyway.

with open('lib/router/app_router.dart', 'w') as f:
    f.write(content)
print("Updated successfully")
