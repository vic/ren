# Ren & Stimpy

![ren](ren-and-stimpy.gif)

> Usage examples: [Fleet Template](ren/templates/fleet/modules) - [vic/vix](https://github.com/vic/vix/tree/ren)

Ren is a small surface language for aspect-oriented, context-driven Nix fleets.
[vic](https://github.com/vic) designed it. [Den](https://github.com/denful/den) inspired it.
If you know Den, you know the ideas. Ren gives them a smaller grammar.
This README is the design. The [fleet template](ren/templates/fleet) is its executable example.

## what-ren-and-stimpy-are

One design, two twin implementations. They exist to measure Gen against `nixpkgs.lib`.
A difference between them must come from the library, never from the fleet.

- [Ren](ren) is built only on [Gen](https://github.com/sini/gen) (`github:sini/gen`, rev `bcbc5ca`).
  Ren is not the next Den. It checks that Gen can implement every [Den capability](#den-coverage).
  [ren/lib](ren/lib) does not use nixpkgs. The realized configs still go through `lib.nixosSystem` and friends.
- [Stimpy](stimpy) is built only on `nixpkgs.lib`. It never uses Gen code.
- Both run one fleet template. `ren/templates/fleet` and `stimpy/templates/fleet` are the same tree.
  Only `flake.nix` and `flake.lock` differ (the input `ren` or `stimpy`).
- Ren knows nothing about hosts, users or NixOS. You declare your own domain. Ren wires it together.
  All kind names below (`environment`, `host`, `mac`) belong to the template, not to Ren.

### usage

```nix
outputs = inputs: inputs.ren.lib.mkFlake inputs (inputs.import-tree ./modules);
```

Stimpy uses the same line with `inputs.stimpy`. Put one concern (aspect) in each file.
Directory names are for humans. Evaluation never reads paths. Paths with `/_` are not loaded.

```
modules/
  helpers.nix
  topology/   fleet, environments, machines, access, channel
  platforms/  nixos, darwin, droid, home-manager, microvm, os, checks
  hosts/      lb, inventory (web-1, web-2), web-2, stage, ci, studio, pixel
  users/      alice, bob
  features/   web, deploy, dns, sync, kernel, monitoring, ...
```

## vocabulary

Reserved words (22). Ren uses a Gen term only where Gen means the same thing.

| group | words |
|---|---|
| keys | `at into below spawns is to fold includes excludes` |
| predicates | `and anyOf not when within has is same` |
| folds | `list set attrs one` |
| bindings | `parent outputs` |

`at` means "which scopes" on every noun. A kind, instance or aspect ref is also a predicate.

### kinds

- A kind is typed, strict data. Every field has a type. An unknown or missing field is an error. Freeform is not allowed.
- `below = [ K … ]` lists the child kinds. This is gen-scope's direction: the parent lists its children.
- `spawns.<K> = s: { <name> = <instance>; }` picks the K children of scope `s`. The default is every instance of K.
- A `spawns` key that is not in `below` is an error.
- A root kind has a non-empty `below`, and no `below` lists it. Each of its instances is a root scope.
- Any other kind that no `below` lists has no scopes. It is data (`channel`, `group`, `db`, `region`) or abstract (`machine`).
- `is = K` makes a subkind. It matches K and has K's fields. `below` and `spawns` are not inherited.
- A function kind `{ db, region }: when (…) { }` takes instances as args. `when` decides which args make an instance.
- One kind in several files merges: `below` concatenates (no duplicates), `spawns` merges by child, fields must agree.
- A field must not have the name of a module key (`key`, `imports`, `config`, …), an instance internal (`name`, `kind`, …), `lib` or `pkgs`.

### scopes

- A scope is one instance at one place in the tree. One instance can have many scopes (alice has eight).
- An instance appears at most once on a path. A second time is an error.
- A scope binds each instance on its path under its kind name and every superkind name (through `is`). The nearest one wins: at `ci`, `host` is ci.
- A scope also binds `parent`, the arg fields of a function kind, and every channel pool it receives.

### instances

- An instance is `ren.<kind>.<name>`. A name is unique across a kind family: `ren.host.ci` and `ren.guest.ci` together are an error.
- A ref field takes a ref, never a string. `environment = "prod"` is refused.
- `ren.lib.data x` gives the kind fields of x alone, so x can go into a module option.
- `ren.<kind>` exists for every declared kind. It is empty when the kind has no instances.

### classes

- A class is a module system: `{ at; into; }`, or a list of disjoint branches. Overlapping branches are an error.
- A class without `at` matches every scope.
- `into = { <bindings>, <channels>, outputs, ... }: ms: { … }` gets the modules that landed at the scope.
- A returned key that names a class forwards `ms` to the nearest ancestor-or-self scope with a branch of that class. No such scope is an error.
- A returned key that names a channel is an emission at that scope. The scope must match the channel's `at`.
- The class's own name, and any other key, is a top-level output. Outputs merge by the `attrs` law.
- Forwards chain (class to class to class). A forward cycle is an error.
- Class content gets the `lib` of its own module system (for example `lib.hm` in home-manager), not Ren's.
- Class names and channel names are disjoint.

### channels

- A channel is data: `{ fold; type; at; to; into; }`. In gen-aspects a class key is a module, and a channel key is `raw`.
- `at` gives the emitter scopes. No `at` means any scope, the root too.
- `to = e: <predicate>` gives the receivers of an emission from scope `e`.
- `type` (optional) is a `lib.types` type. Each emission is checked when it is emitted. The error names the emitter scope, the aspect and the channel.
- `into = { <bindings>, ... }: pool: { … }` runs once per receiving scope with at least one emission.
- An `into` key that names a class forwards as class content, like a class forward. A key that names another channel is an error that names both channels. Any other key is a top-level output.

### aspects

- An aspect is a unit of configuration. `at` activates it. An aspect without `at` fires only where it is included.
- `includes` and `excludes` take refs to declared aspects only. An inline aspect or a string is an error.
- `includes` and `excludes` work in the aspect's scopes and their subtrees. `excludes` wins over `includes`.
- An aspect reached by several include paths (a diamond), or by includes and its own `at`, lands once per scope. Identity is the declared path (gen-aspects `key`, one `id_hash`): an include is a reference, never a copy. So a host and its N users that all include one aspect give that aspect once on the host and once per user.
- A key that names a class is config. A key that names a channel is an emission. Any other key is an error.
- A key of an active aspect that lands in none of its scopes is an error.
- One aspect in several files merges like a module option: class content merges as modules, `includes`/`excludes` concatenate, `at` and channel values must agree.
- Content is a module, or a function with an attrset pattern (`{ ... }: v`). A bare `final: prev:` is an error: wrap it.
- Content args are bindings, channel pools and module args. A function gets only the args it names as formals, also with an `@` pattern.
- A binding or pool name that clashes with a module arg is an error.
- Content never reads realized config. Only `into` reads it, through `outputs`.

### predicates

- Refs: a kind ref matches scopes of that kind or a subkind. An instance ref matches the scopes of that instance. An aspect ref matches scopes where that aspect is active.
- `and` tests left to right and stops at the first false. So a kind test can guard a field read: `and [ ren.kinds.host (when (r: … r.host …)) ]`.
- `anyOf`, `not`. Ren never exports `any`: gen-select makes it a tombstone, and it clashes with `lib.any`.
- `when f` sees the scope bindings only.
- `within P`: a proper ancestor matches P. `has P`: a child matches P.
- `same a b` is identity (gen-schema `id_hash`). It needs no scope, so it works on data kinds and inside `spawns`.
- `is P x`: the scope of x on the current path (nearest ancestor-or-self) matches P. No such scope is an error.
- Aspect refs are stratified. A cycle through `not` or `excludes` is an error ("not stratified").

### folds

- `list`: in scope-path order, never in attribute or include order.
- `set`: no duplicates.
- `attrs`: recursive merge. Equal leaves merge. Different leaves are an error.
- `one`: exactly one emission. Zero or two is an error.

### helpers

- `ren.helpers.<name>` is a value that several fleet files share (`lazyAttrsOf raw`: one name, one file). It can be a predicate, a function or a type.
- The fleet adds exactly two module args, `ren` and `inputs`. A shared helper never goes in `_module.args`. A helper for one file is a private `let`.

### entry-points

- Flakes: `ren.lib.mkFlake inputs module`.
- No flakes: a plain `import` with locked `inputs`.
- flake-parts: `flakeModules.default`, option `fleet`.
- Plain `lib.evalModules`: `lib.flakeModule`, option `fleet`. Ren also accepts Gen modules there.
- Tests: `evalFleet inputs module` returns `scopes active landed pools emitted branches outputs forwarded channels forwards` in both twins. `channels` is `name -> { emitters = [ id ]; receivers = emitter -> [ id ]; }`. `forwards` is `[ { class; from; to; } ]` (class forwards and channel `into` forwards).
- Inside the fleet: `ren.lib.result` is the same RESULT without `outputs`. It is lazy and read-only. Read it in an `into` (stratum 3). Deciding kinds, activation or `at` from it is a cycle: a Nix eval error, never a wrong value.
- Ren only: `ren.lib.inspect` is a gen-inspect inspector over the scope graph (edges `child`, `<class>`, `<channel>`): `.render.mermaid`, `.query`, `.select`, `.why`. The template never uses it (#51: mermaid handles keep `/`).

## fleet-walkthrough

Each entry says what the file shows and which rule it exercises. Links point at the Ren copy. The Stimpy copy is identical.

### topology

- [helpers.nix](ren/templates/fleet/modules/helpers.nix#L3-L8): `opt` and `maybe`, published as [`ren.helpers`](#helpers).
- [topology/fleet.nix](ren/templates/fleet/modules/topology/fleet.nix#L6-L19): the root kind `fleet`. It is a root kind because its `below` is not empty. `spawns` defaults to every instance. `system` scopes carry per-system outputs.
- [topology/environments.nix](ren/templates/fleet/modules/topology/environments.nix#L11-L29): parent-side `spawns`. `inEnv` uses `same` before any scope exists (stratum 0). [L31-L42](ren/templates/fleet/modules/topology/environments.nix#L31-L42): `staging` inherits the settings of `prod` through a ref field.
- [topology/machines.nix](ren/templates/fleet/modules/topology/machines.nix#L12-L25): the predicate helper `metal` and the abstract kind `machine` (no `below` lists it). [L27-L33](ren/templates/fleet/modules/topology/machines.nix#L27-L33): `base` reads the `overlays` pool as a content arg.
- [topology/access.nix](ren/templates/fleet/modules/topology/access.nix#L11-L31): a group closure with `same` on data kinds. A user lands on a machine when its environment grants a group in the user's closure. alice is in `ops`, `ops` is in `admin`, and `prod` grants `admin`.
- [topology/channel.nix](ren/templates/fleet/modules/topology/channel.nix#L13-L29): `channel` is a data kind of flake inputs. `pkgsOf` reads pkgs from any instance with `channel` and `system`.

### platforms

- [platforms/nixos.nix](ren/templates/fleet/modules/platforms/nixos.nix#L13-L50): two disjoint branches. The metal branch builds the system and returns `colmena` and `age-manifest` keys. These keys name channels, so they are emissions. The guest branch forwards into the host's `microvm.vms`. [L52-L62](ren/templates/fleet/modules/platforms/nixos.nix#L52-L62): `host` spawns users and the guests that run on it.
- [platforms/microvm.nix](ren/templates/fleet/modules/platforms/microvm.nix#L12-L17): `guest is host` declares its own `below`, so no guest runs in a guest. [L24-L30](ren/templates/fleet/modules/platforms/microvm.nix#L24-L30): `has` selects hosts with a guest child.
- [platforms/darwin.nix](ren/templates/fleet/modules/platforms/darwin.nix#L21-L28): `homeDarwin` is a sub-class, forwarded in place into `homeManager`. [L40-L43](ren/templates/fleet/modules/platforms/darwin.nix#L40-L43): `tiling` is `at` every user, but its key lands only where `homeDarwin` has a branch.
- [platforms/os.nix](ren/templates/fleet/modules/platforms/os.nix#L4-L14): one class key for either OS. Each branch forwards.
- [platforms/home-manager.nix](ren/templates/fleet/modules/platforms/home-manager.nix#L11-L46): one class, four homes, picked by `within`. [L56-L61](ren/templates/fleet/modules/platforms/home-manager.nix#L56-L61): a bundle; each key lands where its class lives. [L62-L77](ren/templates/fleet/modules/platforms/home-manager.nix#L62-L77): `hm-state` and `hm-standalone` set what home-manager requires (`stateVersion`; `username` and `homeDirectory` in standalone homes).
- [platforms/droid.nix](ren/templates/fleet/modules/platforms/droid.nix#L19-L25): `phone` spawns only the users with `phone = true`.
- [platforms/checks.nix](ren/templates/fleet/modules/platforms/checks.nix#L9-L29): a class that writes its own name. Each content key is one `runNixOSTest`.

### hosts

- [hosts/lb.nix](ren/templates/fleet/modules/hosts/lb.nix#L11-L17): an activator. It is `at` one instance and `includes` included-only aspects.
- [hosts/inventory.nix](ren/templates/fleet/modules/hosts/inventory.nix#L4-L12): hosts from [_inventory.json](ren/templates/fleet/modules/hosts/_inventory.json#L1-L16). Names become refs. A string where a ref belongs is refused.
- [hosts/web-2.nix](ren/templates/fleet/modules/hosts/web-2.nix#L4-L8): substitute = `excludes` + `includes`.
- [hosts/stage.nix](ren/templates/fleet/modules/hosts/stage.nix#L4-L14): a host on the `edge` channel, with a desktop. `sync` reads `desktop` with `is`.
- [hosts/ci.nix](ren/templates/fleet/modules/hosts/ci.nix#L4-L10): a guest on stage, with its own `stable` channel.
- [hosts/studio.nix](ren/templates/fleet/modules/hosts/studio.nix#L4-L9), [hosts/pixel.nix](ren/templates/fleet/modules/hosts/pixel.nix#L4-L8): a mac and a phone in staging.

### users

- [users/alice.nix](ren/templates/fleet/modules/users/alice.nix#L18-L24): a host-qualified aspect (Den `tux@igloo`).
- [users/bob.nix](ren/templates/fleet/modules/users/bob.nix#L11-L18): `has ren.user.bob` reads the same spawns result that put bob there. It cannot drift from the grant rule.

```nix
ren.aspects.docker = {
  at = and [ ren.kinds.host (has ren.user.bob) ]; # the hosts bob lives on
  nixos.virtualisation.docker.enable = true;
  persist = { ... }: "/var/lib/docker";
};
```

### features

- [features/web.nix](ren/templates/fleet/modules/features/web.nix#L14-L25): a channel `to` built from `and`, `when`, `same` and an aspect ref. The kind test guards `r.host`. [L39-L45](ren/templates/fleet/modules/features/web.nix#L39-L45): an aspect ref in `at`. [L48-L60](ren/templates/fleet/modules/features/web.nix#L48-L60): a VM check. [L63-L70](ren/templates/fleet/modules/features/web.nix#L63-L70): the activator.
- [features/deploy.nix](ren/templates/fleet/modules/features/deploy.nix#L12-L31): `fold = one`, `tags` as a plain emission, and the `colmena` channel with `into`. [L33-L47](ren/templates/fleet/modules/features/deploy.nix#L33-L47): one aspect emits into two channels.
- [features/dns.nix](ren/templates/fleet/modules/features/dns.nix#L7-L18): a value-gated class (`when`). [L26-L27](ren/templates/fleet/modules/features/dns.nix#L26-L27): `base` gets a second key from another file. The two definitions merge.
- [features/sync.nix](ren/templates/fleet/modules/features/sync.nix#L13-L27): `devices` through `parent`. [L41](ren/templates/fleet/modules/features/sync.nix#L41): `is ren.aspects.desktop parent` in content. [L38-L40](ren/templates/fleet/modules/features/sync.nix#L38-L40): a placeholder device id. A real fleet keeps the id in a kind field.
- [features/kernel.nix](ren/templates/fleet/modules/features/kernel.nix#L12-L19): the shared type helper `settingsT`. [L31-L36](ren/templates/fleet/modules/features/kernel.nix#L31-L36): the nearest non-null setting wins.
- [features/monitoring.nix](ren/templates/fleet/modules/features/monitoring.nix#L7-L16): a function kind. [L18-L23](ren/templates/fleet/modules/features/monitoring.nix#L18-L23): a typed channel.
- [features/impermanence.nix](ren/templates/fleet/modules/features/impermanence.nix#L12-L22): `to = e: e.host` needs a `host` binding. Users under mac, phone and home have none, so `at` keeps only the users within a host.

```nix
at = anyOf [ ren.kinds.host (and [ ren.kinds.user (within ren.kinds.host) ]) ];
to = e: e.host;
```

- [features/flake-inputs.nix](ren/templates/fleet/modules/features/flake-inputs.nix#L4-L21): a channel `into` that returns a class key. It forwards to the `flake-file` class at the root.
- [features/packages.nix](ren/templates/fleet/modules/features/packages.nix#L4-L14): per-system outputs through a channel `into`. `tools.packages` is data, not a module.
- [features/secrets.nix](ren/templates/fleet/modules/features/secrets.nix#L8-L19), [features/vars.nix](ren/templates/fleet/modules/features/vars.nix#L5-L19): fleet-wide collectors with `to = _: ren.fleet.main`. A channel without `at` also takes root emissions.
- [features/overlays.nix](ren/templates/fleet/modules/features/overlays.nix#L10-L16): a function value is wrapped in `{ ... }:`.
- [features/dev.nix](ren/templates/fleet/modules/features/dev.nix#L5-L17): `anyOf` over two kinds. `os` uses `environment.systemPackages`, which exists in NixOS and nix-darwin.
- [features/motd.nix](ren/templates/fleet/modules/features/motd.nix#L4-L10): `environment.etc.motd.text` exists in both OSes. `motd-short` is included only.
- [features/ssh-agent.nix](ren/templates/fleet/modules/features/ssh-agent.nix#L5-L8): `within machine` keeps it out of standalone homes.
- [features/facter.nix](ren/templates/fleet/modules/features/facter.nix#L4-L12): config gated on a file that exists.

## evaluation-order

| stratum | computes | reads | a cycle inside it is |
|---|---|---|---|
| 0 scopes | `below`/`spawns` tree, `is`, `parent`, `within`, `has K` | instances, `same`, `when` on bindings | refused (see [open](#open)) |
| 1 activation | `at`, `includes`, `excludes`, aspect refs | stratum 0 | an error "not stratified" through `not`/`excludes` |
| 2 content | aspect values, channel folds, `is P x` | strata 0-1, pools (lazy) | Nix infinite recursion, never a wrong value |
| 3 classes | `into`: forwards, outputs; channel `into` | strata 0-2; `outputs` of classes this branch does not forward into | an error from a static check on one graph of classes and channels |

Stratum 3 edges: a K branch returns channel key c (K to c) or class key K' (K to K'). A channel `into` returns class key K (c to K).
Keys are probed without forcing `ms`, the pool or `outputs`. The error names the cycle: ``ren: stratum 3 cycle: class `K` -> channel `c` -> class `K` ``.

## expected-results

T = [template tests](ren/templates/fleet/tests), E = [e2e tests](ren/templates/fleet/tests-e2e), L = lib tests ([Ren](ren/templates/ci/modules/lib), [Stimpy](stimpy/tests)). Test names drop the `test-` prefix.

| row | what appears | what must not appear | tests |
|---|---|---|---|
| fleet docs from the result (#48) | `docs.mermaid` lists every scope id and the forward edges, for example `guest:ci` -->|nixos| `host:stage` | a diagram built from predicates; a read of `ren.lib.result` that decides `at` evaluating | [T docs](ren/templates/fleet/tests/docs.nix) |
| fold one | `deploy.nodes.lb.hostname = "10.0.1.1"` | two `deployment` emitters on one host | T [deployment-lb-address](ren/templates/fleet/tests/pools.nix#L9), [error-two-deployment-emitters](ren/templates/fleet/tests/errors.nix#L79), E [fold-one](ren/templates/fleet/tests-e2e/default.nix#L87) |
| fold list order | lb's haproxy lists web-1, then web-2 | order from attribute or include order | T [backends-lb-exact](ren/templates/fleet/tests/pools.nix#L36), E [fold-list-order](ren/templates/fleet/tests-e2e/default.nix#L91) |
| guest channel | ci (`stable`) built with stable pkgs inside stage (`edge`) | ci built with the pkgs of stage | T [guest-ci-channel-stable](ren/templates/fleet/tests/channels.nix#L8), E [guest-ci-stable-pkgs](ren/templates/fleet/tests-e2e/default.nix#L18) |
| chained forward | bob's home in ci, in ci's nixos, in stage's `microvm.vms.ci.config` | bob's ci home in stage's own `home-manager.users` | T [forwarded-stage-not-ci-users](ren/templates/fleet/tests/collect.nix#L300), E [chained-forward-ci-bob](ren/templates/fleet/tests-e2e/default.nix#L111) |
| darwin + `os` | `darwinConfigurations.studio`: hostName, motd, git, dock; alice and bob homes | studio in `nixosConfigurations` or colmena; kernel or impermanence on studio | T [outputs-nixos-no-studio-no-ci](ren/templates/fleet/tests/collect.nix#L69), [kernel-not-on-studio](ren/templates/fleet/tests/activation.nix#L31), E [darwin-dock](ren/templates/fleet/tests-e2e/default.nix#L167), [darwin-hm-users](ren/templates/fleet/tests-e2e/default.nix#L28) |
| standalone home | `homeConfigurations.alice-laptop` (edge HM): git, syncthing | ssh-agent in alice-laptop | T [ssh-agent-not-standalone](ren/templates/fleet/tests/activation.nix#L22), E [home-edge-hm](ren/templates/fleet/tests-e2e/default.nix#L23), [home-no-ssh-agent](ren/templates/fleet/tests-e2e/default.nix#L159) |
| host-qualified | htop in alice's home on web-1 only | htop elsewhere, or for bob | T [htop-only-alice-web1](ren/templates/fleet/tests/activation.nix#L17), [landed-hm-htop-web1-only](ren/templates/fleet/tests/collect.nix#L190) |
| substitute | web-2 motd "ren"; others "managed by ren" | both motd values on web-2 | T [landed-os-web2-short](ren/templates/fleet/tests/collect.nix#L148), E [substitute-web-2](ren/templates/fleet/tests-e2e/default.nix#L79) |
| `has` | docker on stage and ci (bob lives on both) | docker on prod hosts | T [docker-active](ren/templates/fleet/tests/activation.nix#L9) |
| `parent` | alice's syncthing devices = her other parents | branching on `host ? null` | T [devices-alice-lb](ren/templates/fleet/tests/pools.nix#L57), [devices-excludes-own-parent](ren/templates/fleet/tests/pools.nix#L81) |
| per-system | `packages.<3 systems>.hello` | packages keyed by host | T [tools-three-systems](ren/templates/fleet/tests/activation.nix#L90), E [packages-hello](ren/templates/fleet/tests-e2e/default.nix#L138) |
| overlays | every machine has the helix overlay | the overlay twice on ci | T [overlays-ci-once](ren/templates/fleet/tests/pools.nix#L137), E [overlays-helix-every-machine](ren/templates/fleet/tests-e2e/default.nix#L47) |
| impermanence (`set`) | stage persists the nginx, docker and both syncthing dirs, once each | ci's docker dir on stage; a duplicate | T [persist-stage](ren/templates/fleet/tests/pools.nix#L93), [persist-ci-has-own-docker](ren/templates/fleet/tests/pools.nix#L106), E [persist-no-dups](ren/templates/fleet/tests-e2e/default.nix#L130) |
| name uniqueness | — | `ren.host.ci` and `ren.guest.ci` both | T [error-host-ci-duplicates-guest-ci](ren/templates/fleet/tests/errors.nix#L23) |
| output merge | equal leaves merge | two scopes writing different values at one output | T [output-merge-equal-leaf](ren/templates/fleet/tests/conflicts.nix#L46), [output-merge-conflict](ren/templates/fleet/tests/conflicts.nix#L51) |
| content-function rule | — | a bare `final: prev:` as content | T [error-bare-overlay-function](ren/templates/fleet/tests/errors.nix#L40), [error-bare-class-function](ren/templates/fleet/tests/errors.nix#L53) |
| `homeDarwin` | aerospace in alice's and bob's homes on studio only | aerospace in a linux, phone or standalone home | T [landed-homedarwin-tiling](ren/templates/fleet/tests/collect.nix#L185), E [aerospace-studio-not-lb](ren/templates/fleet/tests-e2e/default.nix#L36) |
| tags = emission | colmena tags for stage include `web` | a `tags` key reserved by Ren | T [deployment-stage-tags-web](ren/templates/fleet/tests/pools.nix#L27) |
| flake-file | `flake-file.inputs.{agenix,microvm}` once, from the root class | an input of an inactive aspect; two different agenix urls | T [outputs-flake-file-inputs](ren/templates/fleet/tests/collect.nix#L138), [emitted-flake-inputs-only-active](ren/templates/fleet/tests/collect.nix#L29), [error-agenix-url-conflict](ren/templates/fleet/tests/errors.nix#L67) |
| recursive `attrs` | `deploy.nodes` and `colmena` merged from four host scopes | a conflict between hosts on `deploy` | T [outputs-deploy-nodes](ren/templates/fleet/tests/collect.nix#L90), [outputs-colmena-nodes](ren/templates/fleet/tests/collect.nix#L80) |
| root emission | a `flake-inputs` emission at `ren.fleet.main` reaches `flake-file.inputs` | root emissions dropped | T [flake-inputs-root](ren/templates/fleet/tests/pools.nix#L164), [emitted-overlays-root](ren/templates/fleet/tests/collect.nix#L10) |
| `attrs` in `into` | `packages.x86_64-linux` from two aspects | two different `hello` values | T [into-attrs-equal-leaf](ren/templates/fleet/tests/conflicts.nix#L56), [into-attrs-conflict](ren/templates/fleet/tests/conflicts.nix#L61) |
| per-branch stratum 3 | a branch reads `outputs` of a class it does not forward into | a branch that reads `outputs` of its forward target | L [Ren](ren/templates/ci/modules/lib/mkflake-strata.nix#L53-L58), [Stimpy](stimpy/tests/collect.nix#L131-L145). No template branch reads `outputs` |
| parent-side `spawns` | users on each machine from `usersOn`; alice on pixel and alice-laptop | `spawns.user` on a kind without `user` in `below` | T [spawn-pixel-only-alice](ren/templates/fleet/tests/scopes.nix#L89), [error-spawns-user-without-below](ren/templates/fleet/tests/errors.nix#L95) |
| no guest in a guest | — | a guest `on` a guest that makes a scope | T [extra-guest-on-guest-no-scope](ren/templates/fleet/tests/scopes.nix#L106) |
| identity without scopes | `closure` and `granted` compare groups with `same` | a scope for a data kind | T [data-kinds-have-no-scopes](ren/templates/fleet/tests/scopes.nix#L111), [spawn-lb-only-alice](ren/templates/fleet/tests/scopes.nix#L54) |
| `is P x` on the path | stage users' syncthing tray on | `is` that picks another scope; `is` on a bare instance | T [is-bare-instance-throws](ren/templates/fleet/tests/surface.nix#L24), E [tray-stage-alice](ren/templates/fleet/tests-e2e/default.nix#L151), [tray-lb-alice](ren/templates/fleet/tests-e2e/default.nix#L155) |
| `anyOf` | `ren.lib.anyOf` | `ren.lib.any` | T [anyOf-not-any](ren/templates/fleet/tests/surface.nix#L29) |
| channel `into` | `packages`, `colmenaHive`, `ageManifest` | `tools.packages` evaluated as a module | T [packages-pool-receivers](ren/templates/fleet/tests/pools.nix#L172), E [channel-into-colmena-age](ren/templates/fleet/tests-e2e/default.nix#L63) |
| channel `into` forward | `flake-file.inputs` forwarded to the root class | a forward with no target scope | T [flake-file-forwarded-lands](ren/templates/fleet/tests/flake-file.nix#L13), L [Ren](ren/templates/ci/modules/lib/mkflake-chan-into.nix#L59), [Stimpy](stimpy/tests/chan-into.nix#L62) |
| channel-to-channel key | — | a channel `into` that returns the key of another channel | L [Ren](ren/templates/ci/modules/lib/mkflake-chan-into.nix#L64), [Stimpy](stimpy/tests/chan-into.nix#L68) |
| class-channel cycle | — | class K emits c, and c forwards to K | L [Ren](ren/templates/ci/modules/lib/mkflake-chan-into.nix#L69), [Stimpy](stimpy/tests/chan-into.nix#L74) |
| hosts from JSON | `host:web-1`, `host:web-2` under prod | `environment = "prod"` (a string for a ref) | T [inventory-hosts-scoped](ren/templates/fleet/tests/inventory.nix#L14), [inventory-string-ref-refused](ren/templates/fleet/tests/inventory.nix#L27), E [inventory-web-1-built](ren/templates/fleet/tests-e2e/demos.nix#L9) |
| generated values | `vars.shared.ca`; `vars.per-machine.<metal>.deploy-key` | entries for ci or studio; values made at eval | T [vars-shared-ca](ren/templates/fleet/tests/vars.nix#L16), [vars-per-machine-metal](ren/templates/fleet/tests/vars.nix#L24), E [vars-plan](ren/templates/fleet/tests-e2e/demos.nix#L14) |
| VM checks | `checks.x86_64-linux.web` with nodes `client`, `web` | a check on another system | T [checks-names](ren/templates/fleet/tests/checks.nix#L9), E [checks-web-nodes](ren/templates/fleet/tests-e2e/demos.nix#L25) |
| `buildHost` | `"10.0.1.1"` for web-2; `null` for lb, web-1, stage | a record for ci or studio | T [buildhost](ren/templates/fleet/tests/checks.nix#L18) |
| facter | active on lb, web-1, web-2, stage | `reportPath` without a report file | T [facter-metal](ren/templates/fleet/tests/checks.nix#L28), E [facter-no-report](ren/templates/fleet/tests-e2e/demos.nix#L41) |
| channel `type` | lb's `scrape` pool holds r1's `{ job; target; }` | a bad emission; an error without scope, aspect and channel | T [typed-scrape-good-emission-passes](ren/templates/fleet/tests/types.nix#L24), [typed-scrape-nested-bad-field-refused](ren/templates/fleet/tests/types.nix#L34) |
| diamond | nginx reached through `web` and `status` lands once on web-1 and stage; lb's haproxy names web-1 once | nginx's content twice in one scope; web-1 twice in a list fold or in haproxy's config | T [diamond](ren/templates/fleet/tests/diamond.nix), E [diamond](ren/templates/fleet/tests-e2e/diamond.nix) |
| merge across files | `base` with keys from two files | — | T [base-merged-across-files](ren/templates/fleet/tests/collect.nix#L122) |
| helpers | every shared helper in `ren.helpers` | a helper in `_module.args` | T [helpers-in-ren-helpers](ren/templates/fleet/tests/helpers.nix#L33), [helpers-not-module-args](ren/templates/fleet/tests/helpers.nix#L38) |
| instances as data | `ren.lib.data x` in a module option | a field named `key`, or an internal | T [data-into-option](ren/templates/fleet/tests/data.nix#L59), [field-key-refused](ren/templates/fleet/tests/data.nix#L55) |
| inline include | a ref include lands | an inline aspect in `includes` | T [error-inline-include](ren/templates/fleet/tests/errors.nix#L106) |
| class `lib` | `lib.hm` in home-manager content | Ren's `lib` in class content | E [class-content-sees-class-lib](ren/templates/fleet/tests-e2e/class-lib.nix#L24) |
| not stratified | — | a cycle through `not`/`excludes` | L [Ren](ren/templates/ci/modules/lib/activation-cycles.nix#L42), [Stimpy](stimpy/tests/activation.nix#L121) |

## gen-mapping

What `ren/lib` calls today (`grep -rho 'gen\.[a-z]*' ren/lib`). Stimpy calls no Gen code.

| Ren construct | Gen part | status |
|---|---|---|
| `ren.lib.inspect` (Ren only) | gen-inspect `mkInspector` / `fromGraph` | direct |
| scope tree, `below`/`spawns` | gen-scope `mkKinds`, `eval`; spawned ids are minted `bare@parent` | glue: kinds become depth levels ([sini/gen-scope#2](https://github.com/sini/gen-scope/issues/2)) |
| `and anyOf not within has` | gen-select, same names | direct |
| kind, instance, aspect refs; `is` | gen-select `when` | glue: gen-select `kind`/`subkind`/`entity` need gen-schema kinds |
| `when f` | gen-select `when` | 1-line adapter |
| `same` | gen-schema `evalSchema`, `identityHashForKind` | direct |
| typed strict kinds | gen-merge `evalModuleTree`, `types` | glue (not gen-schema registries) |
| folds `list`/`one` | gen-scope `folds.list`/`folds.one` | direct |
| folds `set`/`attrs` | gen-scope has no dedup set fold; its `mergeAttrs` is shallow | gap ([sini/gen-scope#2](https://github.com/sini/gen-scope/issues/2)) |
| aspect cycle check | gen-graph `topoOrder` | direct |
| aspects, `includes`, `excludes` | gen-aspects and gen-program not called; Gen has no exclude | gap |
| class/channel keys, landing | gen-aspects `keyCategory` not called | gap |
| classes, forwards, channel `into` | gen-delivery not called | gap ([#6](https://github.com/vic/ren/issues/6)) |
| `lib` without nixpkgs | gen-prelude, gen-merge; `lib/gen-lib.nix` shims seven helpers | gap ([sini/gen-prelude#1](https://github.com/sini/gen-prelude/issues/1)) |
| importing Gen | `import gen { }` | about 20s of the test run ([sini/gen#2](https://github.com/sini/gen/issues/2)) |

## den-coverage

Every user-facing pattern in Den's docs, templates, CI tests, issues and Matrix log. Out of scope: cross-flake namespaces (gen-link), angle brackets, import-tree, diagrams, `denTest`, nh apps.

| Den pattern | Ren | status |
|---|---|---|
| aspect class bundle | one aspect with several class keys (`hm-module`) | covered |
| `includes`, nested aspects, glob of children | `includes = [ … ]`; `lib.attrValues ren.aspects.<group>` | covered |
| inline fn include | an `includes` element must be a ref ([#35](https://github.com/vic/ren/issues/35)) | refused for now |
| parametric `{ host, user }:`, arg-shape gating | content args = bindings; activation is `at`, never the arg shape | covered |
| misplaced entity arg is silently inert | a content arg with no binding is an error | refused |
| `excludes`, `substitute`, `filterBy`, `.global` | `excludes` (subtree); substitute = `excludes` + `includes`; global = at the root | covered |
| exclude by string; exclude that removes nothing | refs only; a warning | covered |
| `tux@igloo`, `provides.to-users`, `provides.to-hosts` | `and` + `within` / `has` predicates | covered |
| `hasAspect`, `.forClass`, `includeIf`, `host-aspects` | an aspect ref in `at` (stratified); `is P x` in content | covered |
| `hasAspect` in `includes` recurses | a cycle is a named error | refused |
| `den.hosts`, `den.homes`, schema, custom kinds | `ren.kinds.*` + instances; always strict | covered |
| freeform schema | — | refused |
| `den.schema.<kind>.includes`, `den.default` | aspect `at = ren.kinds.<kind>` or `anyOf` | covered |
| `policy.resolve`, enrich, relationship fan-out | `below` + `spawns`; a kind field; function kinds | covered |
| `policy.include`/`when`/`for`, `mkPolicy`, shared resolve | `at` predicates; no policies | covered |
| `policy.provide`/`route`/`deliver`/`forward`, hmPlatforms | class `into` returning a class key; a sub-class in place (`homeDarwin`) | covered |
| `policy.instantiate`, `intoAttr`, deliver modes | `into` returns top-level keys: imports, a path, or a sub-eval | covered |
| homeManager content at host scope is inert | landing nowhere is an error | refused |
| isolated entity, `collectSubtree` | guest kind + guest branch; content lands only in its own scopes | covered |
| chained forward classes | forwards chain, acyclic | covered |
| quirks, pipes (`collect`, `broadcast`, `to`, `withProvenance`) | channels: `at`, `to` predicates, `fold`; provenance in the value | covered |
| quirk `{ config, ... }:` thunk, cross-host config | content never reads config; `into` reads `outputs` (stratum 3) | refused |
| quirk named like a class | class and channel names are disjoint | covered |
| diamond: mixed aspect via N users to one host ("defined multiple times", den#468 `<class>@<identity>` dedup) | one atom per (aspect, scope): lands once per scope; a host class key never lands at a user scope | covered |
| identical values merge, different values error | the `attrs` law | covered |
| one aspect in several files | merges like a module option | covered |
| schema on quirk values | channel `type` | covered |
| settings, reservedKeys, `mkDefault` | `settingsT` per kind; no default = required | covered |
| collision policy `den-wins`/`class-wins` | a name clash with a module arg is an error; no knob | covered |
| batteries (hostname, define-user, unfree, wsl, …) | ordinary aspects shipped by a library | covered |
| custom classes (`os`, hjem, maid, devshell, roleClass, nixClass) | `ren.classes`; a class list with branches | covered |
| flake outputs per system, `flake` class | `system` kind + `packages` channel `into` | covered |
| per-aspect flake inputs | `flake-inputs` channel + `flake-file` class | covered |
| ACL environments, recursive groups | `group` kind + `closure` + `granted` | covered |
| overlays, unstable channel, patched nixpkgs | `channel` kind; `overlays` channel | covered |
| standalone home, `user@host` home, home with `osConfig` | `home` kind; the standalone branch reads `outputs` | covered |
| microvm, terranix, k8s, nix-on-droid | `guest` kind; `terraform` class (`when`); `droid` class | covered |
| impermanence collector | `persist` channel, `fold = set` | covered |
| colmena, deploy-rs, tags | `deployment` channel (`one`), `tags` channel (`set`) | covered |
| checks, secrets manifest, generated vars | `checks` class; `age-manifest` and `generators` channels | covered |
| `meta`, fixed-point `config` self-ref | Nix `let`/`rec` in the file | covered |
| noflake, flake-parts, den as a library | [entry points](#entry-points); Ren has no domain names | covered |
| specialisations, variants | a `variant` kind + a class that forwards to `specialisation` | covered (not shown) |
| deterministic ids, ports, IPs | a `let` allocator over sorted names (stratum 0) | covered (not shown) |
| patch a third-party aspect before merge | an override form | change needed |
| nested aspect groups without `provides` | a rule that tells a group from an aspect | change needed |
| use Ren aspects outside Ren | `ren.lib.moduleOf aspect scope` | change needed |
| priority by specificity | instance ref > kind ref, mapped to `mkOverride` | change needed |
| explain/trace resolution, option docs, diagrams, LSP | tooling over the strata data | change needed |
| host users declared inside an aspect | existence is `spawns`, stratum 0 | refused |
| real-host config from a standalone home | a home has no host scope | refused |

## diamond-safety

Den's hardest bug was the diamond. [drupol's review](https://not-a-number.io/2026/evaluating-den-a-dendritic-configuration-framework/) shows the shape, and the [follow-up](https://not-a-number.io/2026/den-framework-follow-up-issue-fixed/) explains the fix (den#468). In the shape, a host has users alice and bob. A mixed aspect `base` (`nixos` + `homeManager`) goes to both users, and each user forwards its `nixos` part back to the one host. The host then gets the same `nixos` content once per user: `boot.kernelPackages is defined multiple times while it's expected to be unique`. Den fixed it with a `<class>@<identity>` dedup key, and anonymous aspects stay outside that fix.

Ren and Stimpy are safe by construction. No dedup pass is needed:

- **Identity is the declared path.** An aspect exists only as `ren.aspects.<name>`. gen-aspects gives it one key and one `id_hash`, whichever include path reaches it. An include is a reference edge, not a copy.
- **No anonymous aspects.** An `includes` element must be a ref. An inline aspect is refused (see [aspects](#aspects)), so nothing can lack an identity.
- **Activation is a set, not a walk.** Each (aspect, scope) pair is one activation atom. A second include path, or an `at` match as well as an include, only adds another reason for that atom to be true. Content lands once per active atom.
- **The den#468 shape is measured, not argued.** An aspect active at every user of `stage` lands its `nixos` content once on stage and never at a user scope ([`test-diamond-host-and-users`](ren/templates/fleet/tests/diamond.nix#L50)).

Evidence:
- Both twins were probed on 8 variants with identical results: plain diamond, includes plus `at`, the den#468 host-and-users shape, an include cycle, two include levels, a users-only include (an error, never a duplicate), and channel emissions from many scopes. Each variant was measured against a `uniq` option, a list option and a list-fold channel.
- The template carries a diamond on purpose: [`status`](ren/templates/fleet/modules/features/status.nix) includes `nginx`, which `web` also reaches. Tests in [`tests/diamond.nix`](ren/templates/fleet/tests/diamond.nix) (tier 1) and [`tests-e2e/diamond.nix`](ren/templates/fleet/tests-e2e/diamond.nix) assert single landing, including the den#468 shape on stage.
- Control: landing once per include path, instead of once per scope, makes the tier-1 diamond tests fail in both twins (1/4), and the e2e haproxy test fails.

## open

- Parent-side `spawns` spreads "where users come from" over five kinds. `usersOn` keeps the rule in one place. A child-side form needs new words (`under`, `picks`).
- Channels with `into`, or a third noun for data outputs? A third noun is clearer, but adds a word.
- `parent` or the kind name? `parent` is for code that is generic over parent kinds. Bind `host` when you mean the host.
- Overlays on guests. Does microvm's `vms.<n>.pkgs` compose with the guest's `nixpkgs.overlays`? Not checked.
- Not shown: per-user classes (hjem, maid), wsl. Each is a class plus a predicate.
- `excludes` is not a Gen term. Gen has no exclude, and nothing in Gen removes an existing include.
- Cyclic `below`: Stimpy refuses it at declaration. Ren accepts it and refuses an instance twice on a path.

Gen-side issues: [#6 realize classes with gen-delivery](https://github.com/vic/ren/issues/6), [#8 smaller hand-rolled Gen primitives](https://github.com/vic/ren/issues/8), [#13 ordered children and ordered kind ancestors](https://github.com/vic/ren/issues/13).

## status-and-testing

Run all checks at the repository root:

```
nix-shell -p just --run 'just ci'
```

- `just twin` checks that both templates are the same tree: `diff -r --exclude=flake.nix --exclude=flake.lock ren/templates/fleet stimpy/templates/fleet`.
- `just ren` and `just stimpy` run one implementation: its `just ci` (treefmt check + nix-unit) and its `just e2e` (realized configs from the template `flake.lock`).
- The template tests are the same for both. The lib suites differ: [ren/templates/ci](ren/templates/ci/modules/lib), [stimpy/tests](stimpy/tests).
