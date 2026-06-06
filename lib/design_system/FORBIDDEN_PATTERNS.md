# Forbidden Patterns

These patterns are **not allowed** in `lib/screens/` and `lib/widgets/` after migration. All styling must flow through design system tokens and components.

## Rules

| Forbidden | Use instead |
|---|---|
| `Color(0x...)` / `Colors.*` | `context.ds.colors.*` or `AppColorTokens.*` |
| Inline `TextStyle(...)` | `context.ds.typography.*` or `AppText` |
| `FontWeight.bold` / `w500`–`w900` | Weight 400 + size hierarchy |
| `ElevatedButton` / `OutlinedButton` / `TextButton` | `AppButton` |
| Arbitrary `EdgeInsets.all(20)` etc. | `AppSpacing.*` presets |
| One-off `Container(decoration: BoxDecoration(...))` for cards | `AppCard` |
| `BoxShadow` for elevation | `AppElevation.hairline` border |
| `BorderRadius.circular(12/16/20)` | `AppRadii.sm` or `AppRadii.pill` |
| Solid white borders on outline pills | `AppBorders.outlinePill` (translucent) |
| Raw `showDialog` + styled `AlertDialog` | `showAppDialog` / `showAppConfirmDialog` |
| Raw `SnackBar` with inline styles | `showAppToast` |
| Light theme / `ThemeData.light` | Dark canvas only per DESIGN.md |

## Allowed exceptions

- `lib/design_system/` — token definitions may contain hex literals
- Third-party widgets where theming is not exposed (document with a comment)
- `Colors.transparent` for layout tricks (not as a brand color)

## CI audit

Run before every PR that touches UI:

```bash
./scripts/design_system_audit.sh
```

## Code review checklist

1. No new hex values outside `lib/design_system/tokens/colors.dart`
2. No `fontWeight` above 400 in screens/widgets
3. All buttons use `AppButton`
4. All cards use `AppCard` or theme-provided `Card`
5. Spacing values trace to `AppSpacing` constants
6. No `BoxShadow` in screens/widgets

## Analyzer recommendations

Enable in `analysis_options.yaml` when ready:

```yaml
linter:
  rules:
    avoid_redundant_argument_values: true
```

Consider `custom_lint` for AST-level enforcement in a follow-up.
