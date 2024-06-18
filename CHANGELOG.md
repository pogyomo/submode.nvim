# Changelog

## [6.2.0](https://github.com/pogyomo/submode.nvim/compare/v6.1.0...v6.2.0) (2024-06-18)


### Features

* add types to arguments of register, and validate it ([597c2a7](https://github.com/pogyomo/submode.nvim/commit/597c2a78977ee577a39dfc51d23a7967ea2532b0))

## [6.1.0](https://github.com/pogyomo/submode.nvim/compare/v6.0.0...v6.1.0) (2024-06-14)


### Features

* add `default` to `opts` as alternative of `default` in `create` ([1d520f9](https://github.com/pogyomo/submode.nvim/commit/1d520f9e78234f83f60addf7ef1944a0f01d65dc))

## [6.0.0](https://github.com/pogyomo/submode.nvim/compare/v5.3.0...v6.0.0) (2024-06-13)


### ⚠ BREAKING CHANGES

* remove `default` and `seal`, and change signature of `submode.create` ([#26](https://github.com/pogyomo/submode.nvim/issues/26))

### Features

* remove `default` and `seal`, and change signature of `submode.create` ([#26](https://github.com/pogyomo/submode.nvim/issues/26)) ([e2f3323](https://github.com/pogyomo/submode.nvim/commit/e2f332358b6f04e3cac9623e8449ea7aa1156fcf))

## [5.3.0](https://github.com/pogyomo/submode.nvim/compare/v5.2.0...v5.3.0) (2024-06-13)


### Features

* `create` accept callbacks and automatically seal submode ([#24](https://github.com/pogyomo/submode.nvim/issues/24)) ([de89045](https://github.com/pogyomo/submode.nvim/commit/de8904565c225f1b0532e829d8c54618c3c2f084))
* add `submode.seal` to refuse `submode.default` ([#21](https://github.com/pogyomo/submode.nvim/issues/21)) ([076d7cd](https://github.com/pogyomo/submode.nvim/commit/076d7cd3ce6913410b21c157788fd49c7183d047))

## [5.2.0](https://github.com/pogyomo/submode.nvim/compare/v5.1.0...v5.2.0) (2024-06-13)


### Features

* add `submode.default` for define default mapping ([#18](https://github.com/pogyomo/submode.nvim/issues/18)) ([54d3df4](https://github.com/pogyomo/submode.nvim/commit/54d3df441b543dd42d534b11cc7a11770ef7dbae))

## [5.1.0](https://github.com/pogyomo/submode.nvim/compare/v5.0.1...v5.1.0) (2024-06-13)


### Features

* improve error and warning messages ([10e036e](https://github.com/pogyomo/submode.nvim/commit/10e036e22f944223bfc9e7a93ca944eecd7e727f))

## [5.0.1](https://github.com/pogyomo/submode.nvim/compare/v5.0.0...v5.0.1) (2024-06-13)


### Bug Fixes

* abort when submode overriding failed ([2a6e583](https://github.com/pogyomo/submode.nvim/commit/2a6e583323071277d1b9172259541b5f864e5839))

## [5.0.0](https://github.com/pogyomo/submode.nvim/compare/v4.1.0...v5.0.0) (2024-06-13)


### ⚠ BREAKING CHANGES

* emit user events and remove `enter_cb` and `leave_cb`

### Features

* emit user events and remove `enter_cb` and `leave_cb` ([114bba2](https://github.com/pogyomo/submode.nvim/commit/114bba2215cc8c849676ba59c9ed41deb91ff953))

## [4.1.0](https://github.com/pogyomo/submode.nvim/compare/v4.0.0...v4.1.0) (2024-06-13)


### Features

* accept `vim.keymap.del` compatible options at `submode.del` ([28686c6](https://github.com/pogyomo/submode.nvim/commit/28686c6da2154b9413ae006156e8cce5004a2bf0))

## [4.0.0](https://github.com/pogyomo/submode.nvim/compare/v3.0.0...v4.0.0) (2024-06-13)


### ⚠ BREAKING CHANGES

* remove `setup` as this plugin doesn't require no config

### Features

* remove `setup` as this plugin doesn't require no config ([bb9b69f](https://github.com/pogyomo/submode.nvim/commit/bb9b69f09b40d00303512632892208a6e5d8c8a5))

## [3.0.0](https://github.com/pogyomo/submode.nvim/compare/v2.1.0...v3.0.0) (2024-06-13)


### ⚠ BREAKING CHANGES

* remove config and add options to submode

### Features

* remove config and add options to submode ([80498f2](https://github.com/pogyomo/submode.nvim/commit/80498f25d81d57e636377292a9041bb48e9b7e1e))

## [2.1.0](https://github.com/pogyomo/submode.nvim/compare/v2.0.0...v2.1.0) (2024-06-13)


### Features

* `set` and `del` works in submode ([88e2402](https://github.com/pogyomo/submode.nvim/commit/88e2402068c7592e1da30ae4c42c5b871fe198ca))


### Bug Fixes

* add validation when register default mappings ([6322f49](https://github.com/pogyomo/submode.nvim/commit/6322f49b8e6981509d3f7e59f8ee2ece10b16e65))
* validate `opts` as optional ([1f6ef0c](https://github.com/pogyomo/submode.nvim/commit/1f6ef0c23d247a7bc9883cf1e48ad296c7ebf0e3))

## [2.0.0](https://github.com/pogyomo/submode.nvim/compare/v1.1.0...v2.0.0) (2024-06-13)


### ⚠ BREAKING CHANGES

* change behavior of `submode.create`

### Features

* change behavior of `submode.create` ([214757c](https://github.com/pogyomo/submode.nvim/commit/214757cfe0a5f77a5669923f645d3b5d0bbf0a74))

## [1.1.0](https://github.com/pogyomo/submode.nvim/compare/v1.0.0...v1.1.0) (2024-06-13)


### Features

* add `set` and `del`, and deprecate `register` ([bd7fcc0](https://github.com/pogyomo/submode.nvim/commit/bd7fcc0c5c95fd3e703bba49c4e495dc31ff185e))

## 1.0.0 (2024-06-12)


### ⚠ BREAKING CHANGES

* don't pass lhs to rhs

### Features

* 'when_mapping_conflict' now accept 'keep'. ([c2b7b41](https://github.com/pogyomo/submode.nvim/commit/c2b7b419222e8a23701923766af954ae6383af12))
* add 'mode_name' to customize return value of submode.mode() ([d53d852](https://github.com/pogyomo/submode.nvim/commit/d53d852bd79afcbd12df51281e618d31425e1d13))
* add 'show_mode'. ([2743c25](https://github.com/pogyomo/submode.nvim/commit/2743c25230fa7a66add3ee5f837d73036d931034))
* add 'when_submode_exist' to config. ([d6ce018](https://github.com/pogyomo/submode.nvim/commit/d6ce01860bdc5f8d5ffa2e380ad515d2385efb5a))
* can detect mapping confliction and change its behavior. ([20cbd30](https://github.com/pogyomo/submode.nvim/commit/20cbd306c3dcb53f76761a592d28a02e61f66442))
* don't pass lhs to rhs ([f3205a3](https://github.com/pogyomo/submode.nvim/commit/f3205a32175b66e80c08dacf7d34f9889f3e0052))
* register leave key to global ([566153d](https://github.com/pogyomo/submode.nvim/commit/566153d15b668ecad08d18ac5ba0a931f2d65089))
* submode.create() can now register mappings. ([75382b9](https://github.com/pogyomo/submode.nvim/commit/75382b98879135ba607f3bad2ede6a30b2713fd2))
* support neovim 0.9.0 ([de97e6f](https://github.com/pogyomo/submode.nvim/commit/de97e6f3d1e3461549122e064b3422186ecf2922))
* user can change behavior when key conflict. ([1381824](https://github.com/pogyomo/submode.nvim/commit/138182454295c9741dec16f63ccb479c9d593a6d))
* user can fire callback when enter/leave submode. ([0086508](https://github.com/pogyomo/submode.nvim/commit/00865082712b4f5a05d36b438e68b8c6e7fcc475))
* user can pass list of key to lhs of mappings. ([a089da0](https://github.com/pogyomo/submode.nvim/commit/a089da030a92f769b06507aa6813e7adc369324c))


### Bug Fixes

* add assertion when enter submode ([eee9c25](https://github.com/pogyomo/submode.nvim/commit/eee9c25cd62d4ef90e18006b7f92b27e0a844ade))
* add missing validation ([196f545](https://github.com/pogyomo/submode.nvim/commit/196f545d60f4dbc014a282c4838599ab9c9d7594))
* capture buffers which doesn't belong to window ([8526f76](https://github.com/pogyomo/submode.nvim/commit/8526f76429887464f8ad3dc2edeaed80533b238a))
* check the buffer is valid or not when restore buffer-local keymap ([af4a804](https://github.com/pogyomo/submode.nvim/commit/af4a8043aced349c0d4cf02340a3073456bef9f4))
* correct return type ([0912c97](https://github.com/pogyomo/submode.nvim/commit/0912c9777765d79b58f8bf725ce6e9b6ecdb8c42))
* ensure to use callbacks which the submode have ([f3de213](https://github.com/pogyomo/submode.nvim/commit/f3de21359a8c5ab143dc810c94e3717e11b56efc))
* register leave keys to all buffers ([#3](https://github.com/pogyomo/submode.nvim/issues/3)) ([04a474b](https://github.com/pogyomo/submode.nvim/commit/04a474bf97757486eae65551ae3c2363d0f07be6))
* remove unused import ([dacdbd3](https://github.com/pogyomo/submode.nvim/commit/dacdbd3e7968762e6cb9710e3642e2bf1a93b43e))
* remove warnings ([f5ae44c](https://github.com/pogyomo/submode.nvim/commit/f5ae44cb63cdf78bf74fd1e64fa8c2c96ffdb13a))
* replace undefined function with builtin function ([be9e243](https://github.com/pogyomo/submode.nvim/commit/be9e243085755863e4904983b5d5771bb0eaf37b))
* suppress warings when using neodev.nvim ([b53d184](https://github.com/pogyomo/submode.nvim/commit/b53d184091717eebf58390c9787d525a5b45bd44))
* suppress warning ([c14327d](https://github.com/pogyomo/submode.nvim/commit/c14327d6837e844ac90482e0279988f1a18225b5))
* use correct type ([61140cc](https://github.com/pogyomo/submode.nvim/commit/61140cc250cf4e2da7ae854ed825815807d767ef))
