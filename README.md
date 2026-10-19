# Ren & Stimpy

![ren](ren-and-stimpy.gif)

Ren is a small surface language for aspect-oriented, context-driven Nix fleets.
Ren was [designed](design/fleet.md) by [vic](https://github.com/vic) and is inspired by [Den](https://github.com/denful/den).
If you know Den, you know the ideas. Ren gives them a smaller grammar.

- [Ren](ren) is built _only_ on [Gen](https://github.com/sini/gen) (`github:sini/gen`).
  Ren is _NOT_ the next version of Den, it is simply a step forward into making sure we
  can use Gen to implement all of [Den capabilities](#how-ren-maps-to-den).
  [ren/lib](ren/lib) makes no use of nixpkgs, neiter lib nor its evalModules. however when the
  full config is realized the generated modules are handled by templates/fleet to lib.nixosSystem
  which will always rely on nixpkgs dependency.
- [Stimpy](stimpy) implements the same [specification](design/fleet.md) only on `nixpkgs.lib`.
  We use it to compare Gen with `nixpkgs.lib`.
- Both run one shared fleet template. Ren knows nothing about hosts, users or NixOS:
  you declare your own domain, and Ren wires it together.



## The grammar

Grammar follows Gen terminology whenever possible.

- **kinds**: the types in your domain. A parent kind lists its child kinds in `below` and picks them with `spawns`.
- **instances**: the named things of a kind, as `ren.<kind>.<name>`.
- **classes**: module systems that receive configuration, with `at` and `into`.
- **channels**: data that flows from emitter scopes to receiver scopes, with a `fold`.
- **aspects**: units of configuration. `at` activates them in matching scopes.

Reserved words (`design/fleet.md`, "Reserved words, v29.A"):

| group | words |
|---|---|
| keys | `at into below spawns is to fold includes excludes` |
| predicates | `and anyOf not when within has is same` |
| folds | `list set attrs one` |
| bindings | `parent outputs` |

A kind, instance or aspect reference is also a predicate. `at` means "which scopes" on every noun.

## Advanced parts, one at a time

All snippets come from the tested [Fleet template](ren/templates/fleet/modules) which was based
on Den capabilities and some other advanced usage patterns from [sini's nix-config](https://github.com/sini/nix-config).

Remember that unlike Den, Ren has no NixOS nor other specific domain knowledge. 
All kind names like `environemnt`, `host`, `mac`, are specific to our Fleet template but you can use
whatever nouns work best to your problem modeling.

When reading these examples it would be helpful to read the corresponding nix files.

### A scope tree from `below` and `spawns`

An environment spawns the machines that name it:

```nix
ren.kinds.environment = {
  below = [
    ren.kinds.host
    ren.kinds.mac
    ren.kinds.phone
  ];
  spawns = {
    host = inEnv ren.host;
    mac = inEnv ren.mac;
    phone = inEnv ren.phone;
  };
```

Each machine kind spawns its users with `spawns.user = usersOn`. A user lands on a machine
when a group in its group closure is granted by the environment (`topology/access.nix`).
alice is in `ops`, `ops` is a member of `admin`, and `prod` grants `admin`.
In Den you write a policy for each edge (`to-fleet`, `fleet-to-envs`, `env-to-hosts`,
`env-users`) and attach each one with `den.schema.<kind>.includes`.

### Predicates as `at`

```nix
_module.args.metal = and [
  ren.kinds.host
  (not ren.kinds.guest)
]; # physical nixos hosts

ren.aspects.vm-host = {
  at = and [
    metal
    (has ren.kinds.guest)
  ];
  nixos.imports = [ inputs.microvm.nixosModules.host ];
};
```

`metal` is a plain value. `has` matches a scope with a matching child. `within` matches a
scope with a matching ancestor: `htop` uses `at = and [ ren.user.alice (within ren.host.web-1) ]`.
In Den you select scopes with policies and `den.schema.<kind>.includes`. In Ren, every
selection is one `at` predicate.

### `includes` and `excludes`

```nix
ren.aspects.quiet = {
  at = ren.host.web-2;
  excludes = [ ren.aspects.motd ];
  includes = [ ren.aspects.motd-short ];
};
```

web-2 drops the default motd and takes the short one. Den has the same pair. In Ren,
`excludes` is an aspect key, and it works in the aspect's scopes and their subtrees.

### Channels with folds

```nix
ren.channels.backends = {
  fold = ren.lib.fold.list;
  at = ren.kinds.host;
  to =
    e:
    and [
      ren.kinds.host
      (when (r: same r.host.environment e.host.environment))
      (not e)
      (not ren.aspects.nginx)
    ];
};
```

`nginx` emits `backends = { host, ... }: host.addr;`. `haproxy` reads `backends` as an
argument. The receivers are the other hosts in the same environment that do not run nginx.
`deployment` uses `fold = one`: each metal host gets exactly one deployment record.
In Den you declare a quirk, write a policy with `pipe.from` and `pipe.collect`, and include
that policy on every host. In Ren, `to` is the collect rule and `fold` is the merge rule.

### Forwarding classes

```nix
ren.classes.os = [
  # one key, either OS
  {
    at = ren.kinds.host;
    into = { ... }: ms: { nixos.imports = ms; };
  }
  {
    at = ren.kinds.mac;
    into = { ... }: ms: { darwin.imports = ms; };
  }
];
```

When `into` returns a key that names a class, Ren forwards the modules to that class.
A guest forwards to its host as `nixos.microvm.vms.${guest.name}`. `homeManager` has four
branches: in a host, in a mac, in a phone, and standalone.
In Den you use forward, provide or route policies for this. In Ren, a forward is a key in `into`.

### Channels with `into`

```nix
ren.channels.colmena = {
  fold = attrs;
  at = metal;
  to = _: ren.fleet.main; # fed by the nixos class
  into = { ... }: nodes: {
    colmenaHive = inputs.colmena.lib.makeHive (
      { meta.nixpkgs = inputs.nixpkgs.legacyPackages.x86_64-linux; } // nodes
    );
  };
};
```

The `nixos` class emits `colmena.${host.name}` for each metal host. The fleet folds them
into one hive. Flake `packages` work the same way, one channel value per `system` scope.
In Den you choose outputs with `policy.instantiate` and `intoAttr`. In Ren, a data output
is a channel with `into`.

### Function kinds

```nix
ren.kinds.db.zone = lib.types.str;
ren.kinds.region.zone = lib.types.str;
ren.kinds.replica = { db, region }: when (s: s.db.zone == s.region.zone) { };
```

A kind can be a function of other instances. `when` guards it: a replica exists only where
its db and region share a zone. Each replica sends a prometheus scrape target to `lb`.

**Strata.** Ren evaluates in four strata: scopes, activation, content, classes (`design/fleet.md`).
A negative cycle through `not` or `excludes` is an eval error. A content cycle is infinite
recursion, never a wrong value.

## How Ren maps to Gen

What `ren/lib` calls today (`grep -rho 'gen\.[a-z]*' ren/lib`), and the Ren code that stands in where Gen is not called yet:

| Ren construct | Gen it calls | Ren glue | status |
|---|---|---|---|
| scope tree, `below` / `spawns` | gen-scope `mkKinds`, `eval` (with `parseParent`) | `lib/scopes.nix`: kinds become depth levels `d0..dM`, because gen-scope refuses a kind in its own `below` | glue ([sini/gen-scope#2](https://github.com/sini/gen-scope/issues/2)) |
| `and anyOf not within has` | gen-select `and` / `anyOf` / `not` / `within` / `has` / `matches` | — | direct |
| kind, instance, aspect refs; `is` subtyping | gen-select `when` | `lib/predicates.nix`: each ref compiles to a `when` closure. gen-select `kind` / `subkind` / `entity` need gen-schema kind values, and Ren kinds are not those | glue |
| `when f` | gen-select `when` | — | 1-line adapter |
| `same` | gen-schema `evalSchema`, `identityHashForKind` | `lib/identity.nix` | direct |
| typed strict kinds, instances | gen-merge `evalModuleTree`, `types` | `lib/kinds.nix`, `lib/kinds-check.nix` (not gen-schema registries) | glue |
| folds `list` / `one` | gen-scope `folds.list` / `folds.one` | — | direct |
| folds `set` / `attrs` | — | `lib/folds.nix` (gen-scope has no dedup set and no recursive attrs merge) | gap ([sini/gen-scope#2](https://github.com/sini/gen-scope/issues/2)) |
| aspect cycle check | gen-graph `topoOrder` | `lib/activation.nix` | direct |
| aspects, `includes`, `excludes`, `has F` | — (gen-aspects, gen-program not called) | `lib/activation.nix` | gap |
| class / channel keys, landing | — (gen-aspects `keyCategory` not called) | `lib/pipeline-out.nix`, `lib/content.nix` | gap |
| classes, forwarding, channels with `into` | — (gen-delivery not called) | `lib/classes.nix` | gap |
| `lib` without nixpkgs | gen-prelude, gen-merge | `lib/gen-lib.nix` shims seven helpers | gap ([sini/gen-prelude#1](https://github.com/sini/gen-prelude/issues/1)) |
| importing Gen | the gen hub, `import gen { }` | — | about 20s of the test run ([sini/gen#2](https://github.com/sini/gen/issues/2)) |

Ren calls 6 of the hub's roster members today: prelude, merge, scope, select, graph and schema. The gap rows are where Ren pushes Gen forward.

## How Ren maps to Den

| Den pattern | Ren construct | status |
|---|---|---|
| aspect class bundle | one aspect with several class keys (`hm-module`), `at = anyOf [ … ]` | covered |
| `includes`, nested aspect, `._` children | `includes = [ … ]`; a group is a plain Nix attrset | covered |
| inline fn include | an anonymous aspect inside `includes` | covered |
| parametric `{ host, user }:` aspect | content args = scope bindings; activation is `at`, never the arg shape | covered |
| class module forms `{ host, config, pkgs, ... }` | content fn args = bindings, channels and module args | covered |
| `excludes`, `exclude` / `substitute` / `filterBy` | `excludes`; substitute = `excludes` + `includes` (aspect `quiet`) | covered |
| `"tux@igloo"` host-qualified aspect | `at = and [ ren.user.alice (within ren.host.web-1) ]` | covered |
| `provides.to-users`, `provides.<user>` | `at = and [ ren.kinds.user (within ren.kinds.machine) ]` | covered |
| `provides.to-hosts`, `provides.<host>` | `at = and [ ren.kinds.host (has ren.user.bob) ]` | covered |
| `{ user, ... }:` nixos per user on host | a class `at` the user scope (`homeManager`), or a host aspect that maps over the host's users | covered |
| `host-aspects` battery | home aspect `at` the user, reading `is ren.aspects.desktop parent` in content | covered |
| `hasAspect`, `.forClass`, `host.aspects` | `is P x`, an aspect ref as predicate (`ren.aspects.nginx`), `has` | covered |
| `den.hosts`, `den.homes`, per-user `classes` | kinds `ren.kinds.host`, `ren.kinds.home` with instances `ren.host.<name>`; a per-user class = a class `at` the user kind with `when` | covered |
| schema extend, freeform, `strict` | kinds are always typed and strict; freeform is not allowed | refused (by design) |
| `den.schema.<kind>.includes` | aspect `at = ren.kinds.<kind>` | covered |
| `den.default` | aspect `at = anyOf [ every kind ]` | covered |
| `fleet` grouping kind | `ren.kinds.fleet` | covered |
| `policy.resolve.to`, `resolve` enrich | `below` and `spawns`; enrich = a kind field or a value computed in `spawns` | covered |
| `policy.include` / `when` / `for` / `mkPolicy` | `at` predicates | covered |
| `policy.provide` / `route` / `deliver` / `forward` / `forwardTo` | class `into` returning a class key (it forwards) | covered |
| `policy.instantiate`, `intoAttr` | `into` returns top-level option keys; no key = no output (guest) | covered |
| host `instantiate` override, patched nixpkgs | `channel` kind instance data (`ren.channel.stable`) used by `into` | covered |
| quirk declare / produce / consume | `ren.channels` + a key in an aspect (emission) + a channel arg in content | covered |
| `pipe.filter` / `transform` / `fold` / `append` / `for` / `as` | plain Nix on the channel value, plus channel `fold` | covered |
| `pipe.to [ aspects ]` | `to = e: and [ … ren.aspects.nginx ]` | covered |
| `pipe.collect` / `collectAll` / `broadcast` / `expose` | `to` predicates: same env (`when` + `same`), any (`ren.kinds.machine`), same instance (`e`), ancestor (`e.host`) | covered |
| `pipe.withProvenance` | emit the source in the value (`{ name; addr; }`) | covered |
| quirk `{ config, ... }` producer thunk | not allowed in content; read realized config only in `into` through `outputs` | refused (by design) |
| settings: `reservedKeys`, required, `mkDefault` / `mkForce` | `settingsT` per kind; no default = required | covered |
| collision policy `den-wins` / `class-wins` | NixOS module merge; a name clash with a module arg is an eval error | covered |
| batteries (`define-user`, `hostname`, `unfree`, `wsl`, …) | ordinary aspects shipped by a library | covered |
| `os`, `user`, hjem, maid, custom classes | `ren.classes`; `os` is one class with a list of branches | covered |
| flake outputs per system, `flake` class | `system` kind + `packages` channel with `into` | covered |
| ACL environments | `group` kind + `closure` + `granted` | covered |
| overlays, `useGlobalPkgs`, unstable channel | `channel` kind; overlays = the `overlays` channel, gated by `when` | covered |
| standalone home, `user@host` home | `home` kind + `homeManager` class branch | covered |
| microvm `resolve` + `provide` | `guest` kind (`is = ren.kinds.host`) + `nixos` class branch at the guest that forwards | covered |
| terranix / k8s `instantiate` | value-gated class (`terraform`, `when`); a cluster kind + class per system | covered |
| impermanence persist collector | `persist` channel, `fold = set` | covered |
| `meta`, fixed-point `config` self-ref | Nix `let` / `rec` in the aspect's file | covered |
| nh apps, diagrams, `policyInspect`, `denTest`, import-tree | tooling | out of scope |

Rows come from "Den coverage" in [`design/fleet.md`](design/fleet.md). The Ren column is rewritten in v30 words. Ren refuses some Den behaviours on purpose: see "Den behaviours Ren refuses" there.

## Usage

```nix
outputs = inputs: inputs.ren.lib.mkFlake inputs (inputs.import-tree ./modules);
```

Stimpy uses the same line with `inputs.stimpy` ([template](stimpy/templates/fleet)).
Put one concern in each file:

```
modules/
  topology/   fleet, environments, machines, access, channel
  platforms/  nixos, darwin, droid, home-manager, microvm, os
  hosts/      lb, web-1, web-2, stage, ci, studio, pixel
  users/      alice, bob
  features/   web, deploy, dns, sync, kernel, monitoring, ...
```

## Status and testing

Both implementations run the shared template (`just ci` at 9ed4bf0):

| | tests | e2e |
|---|---|---|
| Stimpy | 217/217 | 25/25 |
| Ren | 186/186 | 25/25 |

The 112 `templates.*` tests are the same for both; the `lib.*` suites differ. Run all checks at the repository root:

```
nix-shell -p just --run 'just ci'
```
