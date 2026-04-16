## [1.2.0] - 2026-04-16

### 🐛 Bug Fixes

- Dispatch bug for triangular matrices
- Minor fixes for `shrinkable`

### 🚜 Refactor

- Get rid of `InternalTestSet`

### 📚 Documentation

- Build documentation locally
- Bump Documenter.jl
- Fix doctests
- Update `index.md`
- Add cliff configuration file
- Enhance wording of `index.md`

### 🎨 Styling

- Remove extra newlines

### 🧪 Testing

- Switch to new test directory format
- Check for method ambiguities with Aqua
- Do not time main testset
- Move `Aqua.test_all` inside main `@testset`
- Make main `@testset` verbose
- Remove julia-1.7.3 from Github test workflow

### ⚙️ Miscellaneous Tasks

- Update my email address
- Bump manifest's Julia version to 1.12
- Add compat entries for Dates, LinearAlgebra & Random
- Move `export` statements next to exported symbols
- Order `import`s/`using`s alphabetically

