## Creating test cases
When adding test cases please create another test case in any existing registry.
Include `Deps.toml` and `Versions.toml` files to specify when a package has been dependent
on another.


## Overview of Cases

### Case1
Single patch pre-1.0 release that has always been dependent on `DownDep`.

### Case2
Single minor pre-1.0 release that has always been dependent on `DownDep`.

### Case3
Single post-1.0 release that is dependent on `DownDep`.

### Case4
Two releases where `DownDep` was previously a depdenency and no longer is.
