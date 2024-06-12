# Changelog

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
