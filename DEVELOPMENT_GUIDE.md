# Development Guide - NextWave Music Sim

## Code Quality Standards

### Deprecation Policy
**IMPORTANT: Avoid using deprecated or outdated APIs**

- ❌ **DO NOT** use deprecated plugins, libraries, or widget constructors
- ✅ **DO** check Flutter/Dart changelogs when upgrading SDK versions
- ✅ **DO** run `flutter analyze` before committing code
- ✅ **DO** address all deprecation warnings immediately

### Common Deprecated APIs to Avoid

#### Flutter 3.24+ Breaking Changes:
- ❌ `activeThumbColor` → ✅ Use `thumbColor` with `WidgetStateProperty`
- ❌ `initialValue` in `DropdownButtonFormField` → ✅ Use `value`
- ❌ `CardTheme` with complex shapes → ✅ Use simplified `CardThemeData`
- ❌ `MaterialState` → ✅ Use `WidgetState`

#### Best Practices:
- Always use explicit type parameters for `.map()` operations on web
- Use const constructors wherever possible
- Prefer `WidgetStateProperty` over deprecated color properties
- Check package compatibility before adding dependencies

### Before Committing
1. Run `flutter analyze` - must have 0 errors
2. Run `flutter test` - all tests must pass
3. Check for deprecation warnings in output
4. Update dependencies: `flutter pub outdated`

### Package Management
- Review package health scores on pub.dev before adding dependencies
- Prefer packages with:
  - ✅ 100+ pub points
  - ✅ Active maintenance (updated within 6 months)
  - ✅ Null safety support
  - ✅ Flutter 3.x compatibility

### CI/CD Integration
The GitHub Actions workflow will fail if:
- Deprecated APIs are used (treated as errors via `analysis_options.yaml`)
- Build fails due to API incompatibilities
- Tests fail

## Resources
- [Flutter Breaking Changes](https://docs.flutter.dev/release/breaking-changes)
- [Dart Linter Rules](https://dart.dev/tools/linter-rules)
- [Package Versioning Guide](https://dart.dev/tools/pub/versioning)
