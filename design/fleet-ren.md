# Ren fleet demo — ren-v30.1 (2026-10-19) — implementation copy of ren-and-stimpy fleet.md v32

## ren-v30.1 corrections (measured at gen bcbc5ca; the implementation follows this file)
- C1 (L474): gen-scope spawned ids are `bare@parent` (build-nodes.nix:335), not `parent/child`.
- C2 (L489): `one`, `list`, `same`, `mergeAttrs`, `byKey` exist as named gen-scope folds (folds.nix:426). Only `set` is not a gen fold.
- C3 (L18/L101): gen-select `anyOf` exists at bcbc5ca; local ~/hk/gen checkouts are stale.
- C4 (L300): `persist` at = `anyOf [ host (and [ user (within host) ]) ]`. `to = e: e.host` needs a host binding; users under mac/phone/home have none (measured: `attribute 'host' missing`).
- C5 (L427 strata row 3): the per-branch stratum-3 static check (a branch must not read `outputs` it forwards into) is enforced by nix/lib/strata.nix: a static check on the class graph (keys probed per branch); a read of a forwarded-into class's output throws, lazily per key.
- C6 (#16): a content function with an `@` pattern (`a@{ host, ... }:`) sees only the Ren args it names as formals. gen-bind `wrap` passes declared formals only (README.md:152), as nixpkgs does for `_module.args` (lib/modules.nix:725-755). Name every arg you read.


v29.A = genie's fork of vic's v29 (gist `fbc69bfc`). It keeps v29's reduction and fixes the places where a rename to a Gen term inverted or overloaded that term. v29 explores how far the surface can shrink. **The previous version is backed up as `vic/fleet-v28.md`**, and we may revert to it. v29 renames words to Gen's own terms only where Gen means the same thing. It merges words that did the same job, and makes the rest relate to each other. Design only; nothing implements it. Feedback goes after `> VIC:` lines.

## What changed from v30

Vocabulary sweep: every section now uses the v30 words; no semantic change.

## What changed from v29 (genie, v29.A)

Checked against gen origin/main (gen-scope adc5180, gen-select 42a09ef, gen-aspects 1847f11). Nothing was evaluated.

| v29 | v29.A | why | Gen source |
|---|---|---|---|
| kind `below = <parent>; spawns = s: …` on the **child** | `below = [ <child kinds> ]; spawns.<child> = s: …` on the **parent** | gen-scope's `below` points the other way: a kind's `below` lists the kinds *beneath* it (depth = 1 + max over `below`). `spawns` is declared on the host kind, **keyed by the produced kind**, and mkKind refuses a `spawns` entry whose kind is outside the host's own `below`. So v29 used Gen's words with the meaning reversed. Taking Gen's direction also closes v29's own open question: `user` no longer branches on `s ? home` / `s ? phone`, because each parent says how it spawns users | `gen-scope/lib/cascade.nix:10-17` (header), `mkKind { name; below ? [ ]; spawns ? { }; … }` :425-433 |
| `below = metal` (a predicate) | gone | in the parent-side form `below` is a list of kinds, which is what gen-scope takes. A guest inside a guest is ruled out because `guest` declares its own `below`. gen-scope refuses a kind below itself at registration ("a self-naming or cyclic `below` cannot be named at all") | cascade.nix:15-17 |
| `is a b` for identity | `same a b` again | gen keeps identity and matching apart: identity is gen-schema's `id_hash` (gen-select's `entity` compares through `entityEq`), and matching is gen-select. Defining identity as "b's scope matches a" fails in three cases. An instance may have **no** scope (`group` and `channel` are data and never spawn). It may have **many** (alice under eight parents: which one?). And in stratum 0, `spawns` (`inEnv`) needs identity before the scopes it would match exist | gen-schema `id_hash`; gen-select `entityEq` |
| `is P x`: "x's nearest scope" | `is P x`: x's scope **on the current path** (the nearest ancestor-or-self scope bound to x); an eval error if x has none there | "nearest" had no reference point once one instance has many scopes. `is ren.aspects.desktop parent` keeps working, because `parent` is always on the path | — |
| `any` | `anyOf` | `any` is a **tombstone** in gen-select: it throws "`any` is renamed `anyOf`. gen-prelude's `any` is the list predicate". The fleet shows why: `granted` uses `lib.any` and `at` used `any` in the same file | `gen-select/lib/constructors.nix:163-172` |
| non-module collectors are classes (`packages`, `colmena`, `flake-file`, `manifest`) | they become **channels with `into`** | in gen-aspects a `class` key is typed `deferredModule`. `tools.packages = { system, ... }: { hello = …; }` is not a module, and its `{ system, … }` would be resolved as module args. Data keys are gen-aspects `channel`s (`raw`). A channel may declare `into`, which runs once per receiving scope with the folded pool | `gen-aspects/lib/types.nix:9-10` |
| `manifest` reads `outputs` (stratum 3) | the `nixos` collector emits `age-manifest.<h>` from the system it just built | the collector already holds the realized config, so going through `outputs` added a stratum and a cycle check for nothing. `outputs` stays for Den's home-with-`osConfig` case | — |
| a key returned by `into` names a class (forward) or is an output | it may also name a **channel**: an emission at that scope | this is how `nixos.into` feeds `colmena` and `age-manifest` | — |
| v29 line citations | corrected | at origin/main: gen-select `and` :156, `anyOf` :163, `not` :174, `has` :179, `within` :184, `when` :219. gen-aspects `types.nix:9` is the class/channel line; `:42` and `:571` are other code | — |

**Reserved words, v29.A (22):**
- keys `at into below spawns is to fold includes excludes`;
- combinators `and anyOf not when within has is same`;
- folds `list set attrs one`;
- bindings `parent outputs`.

That is one more than v29, because `same` comes back. `is` still covers kind subtyping and predicate tests; identity is the one job it can't do.

**Kinds without scopes.** A kind that no `below` lists has no scopes. It is data (`channel`, `group`, `db`, `region`) or abstract (`machine`). `same` works on it anyway, which is the reason identity stays separate.

## What changed from v28

| v28 | v29 | why | Gen source |
|---|---|---|---|
| `ren.targets` | `ren.classes` | a feature key naming a module system is a **class** in gen-aspects (`keyCategory k == "class"`, deferredModule) | `gen-aspects/lib/guard-term.nix:93`, `types.nix:571` |
| `ren.signals` | `ren.channels` | a feature key carrying raw data is a **channel** in gen-aspects (`channel → raw`) | `gen-aspects/lib/types.nix:9` |
| `ren.features` | `ren.aspects` | a bundle of class and channel keys with `includes` is an **aspect** in gen-aspects | `gen-aspects` |
| `take` / `omit` | `includes` / `excludes` | `includes` is gen-aspects' word; `excludes` is its paired opposite (Gen has no exclude, so Ren names it to match) | `gen-aspects/lib/types.nix:42` |
| kind `at = spawn K f` | kind `below = K; spawns = f;` | gen-scope's own fields `mkKind { spawns; below; }`. `spawns` defaults to all instances, so most kinds need only `below` | `gen-scope/lib/cascade.nix:12-14` |
| `spawn` combinator | removed | replaced by the two kind fields above | |
| several parents `any [ (spawn A f) (spawn B g) ]` | `below = any [ A B ]; spawns = s: …` | one rule per kind; `spawns` branches on `s` | |
| signal `from` | `at` | `at` means "which scopes" on every noun: classes collect there, aspects activate there, kinds are `below` it, channels are emitted there | |
| `from = anywhere` | no `at` | a channel without `at` is emitted from any scope; `anywhere` is gone | |
| `all` / `unless` | `and` / `not` | gen-select's names | `gen-select/lib/constructors.nix:156,166` |
| `contains K` | `has K` | gen-select `has` = "some child matches" | `constructors.nix:171` |
| `has F` (feature active) | the aspect ref itself: `ren.aspects.nginx` | refs are predicates: a kind ref matches scopes of that kind, an instance ref matches that instance's scopes, an **aspect ref matches scopes where that aspect is active** | |
| `has F x` (content) | `is P x` | `is` tests a predicate against an instance's scope | |
| `same a b` | `is a b` | an instance ref is a predicate; `is a b` holds when b's scope matches a, which is identity | gen-schema `id_hash` |
| kind `is = K` | kept | declares the relation that `is P x` tests: `guest is host`, `is ren.kinds.host g` | gen-select `subkind` (`constructors.nix:154`) |
| `within`, `when`, `any` | kept | gen-select names already | `constructors.nix:161,176` and `when` |
| binding `features` | `aspects` | follows the rename | |

**Reserved words**
- **v28 (24):**
  - keys `at into is from to fold take omit`;
  - combinators `all any unless when within contains anywhere has spawn same`;
  - folds `list set attrs one`;
  - bindings `parent outputs`.
- **v29 (21):**
  - keys `at into below spawns is to fold includes excludes`;
  - combinators `and any not when within has is`;
  - folds `list set attrs one`;
  - bindings `parent outputs`.

  Here `is` is counted once, and the bindings `features`/`aspects` and `has` in content are not counted in either version.

**How the words relate**
- `at` = where, on every noun.
- `below` = the parent side of `at`, for kinds.
- `has` and `within` are inverses: child and ancestor.
- `is` is one test, for kinds, instances and aspects alike.
- `includes` and `excludes` are a pair.
- Refs (kind, instance, aspect) are predicates everywhere.

**Open questions on v29**
- **`below` takes a predicate (`metal`).** Gen's `below` takes kind names, so Ren would need glue for that. UNVERIFIED.
- **`excludes` is not a Gen term.** It is named only to pair with `includes`.
- **`user.spawns` branches on `s ? home` and `s ? phone`.** This is less local than v28's three spawn rules. It is the cost of a single `spawns` per kind.
- **The sections after Fleet still use v28 names.** Read them through the table above (`targets` = `classes`, `signals` = `channels`, `features` = `aspects`, `take`/`omit` = `includes`/`excludes`, `contains` = `has`, `has F` = aspect ref).

## Vocabulary (v29.A)

- **kinds**: typed, strict data.
  - `below = [ K … ]` lists the kinds whose scopes this kind's scopes contain (gen-scope's direction).
  - `spawns.<K> = s: { name = instance; … }` picks the K children of scope `s`. The default is every instance of K. A `spawns` key outside `below` is an error.
  - A kind that no `below` lists has no scopes: it is data, or abstract if it is only `is`-ed.
  - `is = K` makes the kind a subkind of K: it matches K and has K's fields. `below` and `spawns` are **not** inherited, so a subkind says what it contains (that's what rules out a guest inside a guest).
  - An instance appears at most once on a path.
- **instances**: `ren.<kind>.<name>`. `ren.lib.data x` is the kind fields of instance x alone, so x can be passed as data into a module option; a field may not be named as a module key (`key`, `imports`, `config`, …) or an instance internal (`name`, `kind`, …), and the kind declaration says which.
- **classes**: module systems. `{ at; into; }` or a list of disjoint branches.
  - `into = { <bindings>, <channels>, outputs, ... }: ms: { … }`.
  - A returned key that names a class forwards. Any other key is a top-level option, merged by `attrs`.
- **channels**: data. `{ fold; at; to; }`.
  - `at` is the emitter scopes; the default is any scope.
  - `to = e: <predicate>` gives the receivers.
  - `fold` is `list` (ordered by scope path), `set`, `attrs` (recursive, conflict = error) or `one`.
- **aspects**: `at` activates. An aspect without `at` fires only where it is included.
  - `includes` and `excludes` work in the aspect's scopes and their subtrees.
  - A key naming a class is config; a key naming a channel is an emission; any other key is an error.
  - A key that lands in none of the aspect's scopes is an error.
- **predicates**: refs (kind, instance, aspect, `e`) plus `and anyOf not when within has`.
- **`same a b`**: identity (gen-schema `id_hash`). It needs no scope, so it works on data kinds and inside `spawns`.
  - `when f` sees bindings only.
  - Aspect refs are stratum 1, stratified; a negative cycle is an error.
- **`is P x`**: x's scope on the current path (nearest ancestor-or-self) matches P; an error if x has none there. It is the same test as `at`, applied to a value.

## Fleet

```nix
let
  inherit (ren.lib) and anyOf not when within has is same;
  inherit (ren.lib.fold) list set attrs one;
  t = lib.types;

  opt   = type: default: lib.mkOption { inherit type default; };
  maybe = type: opt (t.nullOr type) null;
  first = lib.findFirst (v: v != null) null;                       # nearest non-null wins

  pkgsOf = m: m.channel.nixpkgs.legacyPackages.${m.system.name};   # m: anything with channel + system
  inEnv  = xs: s: lib.filterAttrs (_: x: same x.environment s.environment) xs;

  metal = and [ ren.kinds.host (not ren.kinds.guest) ];             # physical nixos hosts

  settingsT = t.submodule { options.kernel.channel = maybe (t.enum [ "lts" "latest" ]); };

  closure = gs: map (x: x.g) (lib.genericClosure {                  # nested groups
    startSet = map (g: { key = g.name; inherit g; }) gs;
    operator = x: map (p: { key = p.name; g = p; })
      (lib.filter (p: lib.any (same x.g) p.members) (lib.attrValues ren.group));
  });
  usersOn = s: lib.filterAttrs (_: granted s) ren.user;
  granted = s: u: lib.any (g: lib.any (same g) s.environment.grants) (closure u.groups);
in
ren.lib.mkFlake inputs {

  # ══ CLASSES — module systems (gen-aspects `class`); into returns top-level options ══
  ren.classes = {

    nixos = [
      { at = metal;
        into = { host, deployment, ... }: ms:
          let sys = host.channel.nixpkgs.lib.nixosSystem { system = host.system.name; modules = ms; };
          in {
            nixosConfigurations.${host.name} = sys;
            colmena.${host.name}      = { imports = ms; deployment = { targetHost = deployment.address; inherit (deployment) tags; }; };   # channel
            age-manifest.${host.name} = lib.attrNames sys.config.age.secrets;                                                       # channel
            deploy.nodes.${host.name} = { hostname = deployment.address; sshUser = deployment.user; };
          }; }
      { at = ren.kinds.guest;                                       # forwards to the physical host
        into = { guest, ... }: ms: {
          nixos.microvm.vms.${guest.name} = { pkgs = pkgsOf guest; config.imports = ms; };
        }; }
    ];

    darwin = {
      at   = ren.kinds.mac;
      into = { mac, ... }: ms: {
        darwinConfigurations.${mac.name} =
          mac.channel.darwin.lib.darwinSystem { system = mac.system.name; modules = ms; };
      };
    };

    os = [                                                          # one key, either OS
      { at = ren.kinds.host; into = { ... }: ms: { nixos.imports  = ms; }; }
      { at = ren.kinds.mac;  into = { ... }: ms: { darwin.imports = ms; }; }
    ];

    homeManager = [                                                 # one class, four homes
      { at = and [ ren.kinds.user (within ren.kinds.host) ];
        into = { user, ... }: ms: { nixos.home-manager.users.${user.name}.imports = ms; }; }
      { at = and [ ren.kinds.user (within ren.kinds.mac) ];
        into = { user, ... }: ms: { darwin.home-manager.users.${user.name}.imports = ms; }; }
      { at = and [ ren.kinds.user (within ren.kinds.phone) ];
        into = { ... }: ms: { droid.home-manager.config.imports = ms; }; }
      { at = and [ ren.kinds.user (within ren.kinds.home) ];       # standalone
        into = { home, ... }: ms: {
          homeConfigurations.${home.name} =
            home.channel.home-manager.lib.homeManagerConfiguration { pkgs = pkgsOf home; modules = ms; };
        }; }
    ];

    homeDarwin = {                                                  # a sub-class, forwarded in place
      at   = and [ ren.kinds.user (within ren.kinds.mac) ];
      into = { ... }: ms: { homeManager.imports = ms; };
    };

    droid = {
      at   = ren.kinds.phone;
      into = { phone, ... }: ms: {
        nixOnDroidConfigurations.${phone.name} =
          inputs.nix-on-droid.lib.nixOnDroidConfiguration { pkgs = pkgsOf phone; modules = ms; };
      };
    };

    terraform = {
      at   = and [ ren.kinds.environment (when (s: s.environment.edge)) ];
      into = { ... }: ms: {
        terraformConfigurations.dns =
          inputs.terranix.lib.terranixConfiguration { system = "x86_64-linux"; modules = ms; };
      };
    };

  };

  # ══ KINDS — below = child kinds; spawns.<child> = s: instances (gen-scope mkKind, parent side) ══
  # A kind no `below` lists has no scopes: data (channel, group, db, region) or abstract (machine).
  ren.kinds = {
    fleet = { below = [ ren.kinds.system ren.kinds.environment ren.kinds.home ren.kinds.replica ]; };   # spawns default: every instance
    system  = { };
    channel = { nixpkgs = t.raw; home-manager = t.raw; darwin = opt t.raw null; };
    group   = { members = opt (t.listOf ren.kinds.group) [ ]; };

    environment = {
      below    = [ ren.kinds.host ren.kinds.mac ren.kinds.phone ];
      spawns   = { host = inEnv ren.host; mac = inEnv ren.mac; phone = inEnv ren.phone; };
      grants   = t.listOf ren.kinds.group;
      edge     = opt t.bool false;
      inherits = maybe ren.kinds.environment;
      settings = opt settingsT { };
    };

    machine = {                                                     # abstract: no `below` lists it
      environment = ren.kinds.environment;
      channel     = ren.kinds.channel;
      system      = ren.kinds.system;
      addr        = t.str;
      settings    = opt settingsT { };
    };
    host  = { is = ren.kinds.machine;
              below  = [ ren.kinds.user ren.kinds.guest ];
              spawns = { user = usersOn; guest = s: lib.filterAttrs (_: g: same g.on s.host) ren.guest; }; };
    mac   = { is = ren.kinds.machine; below = [ ren.kinds.user ]; spawns.user = usersOn; };
    guest = { is = ren.kinds.host;                                  # declares its own `below`: no guest in a guest
              below = [ ren.kinds.user ]; spawns.user = usersOn;
              on    = ren.kinds.host; };

    phone = { below = [ ren.kinds.user ]; spawns.user = _: lib.filterAttrs (_: u: u.phone) ren.user;
              environment = ren.kinds.environment; channel = ren.kinds.channel; system = ren.kinds.system; };
    home  = { below = [ ren.kinds.user ]; spawns.user = s: { ${s.home.user.name} = s.home.user; };   # standalone
              user = ren.kinds.user; channel = ren.kinds.channel; system = ren.kinds.system; };

    user = {                                                        # each parent says how it spawns users
      groups = t.listOf ren.kinds.group;
      phone  = opt t.bool false;
    };

    db.zone     = t.str;
    region.zone = t.str;
    replica     = { db, region }: when (s: s.db.zone == s.region.zone) { };
  };

  # ══ INSTANCES ═════════════════════════════════════════════════════════
  ren.fleet.main = { };
  ren.system.x86_64-linux   = { };
  ren.system.aarch64-linux  = { };
  ren.system.aarch64-darwin = { };

  ren.channel.stable = { nixpkgs = inputs.nixpkgs;          home-manager = inputs.home-manager;          darwin = inputs.nix-darwin; };
  ren.channel.edge   = { nixpkgs = inputs.nixpkgs-unstable; home-manager = inputs.home-manager-unstable; };

  ren.group.ops    = { };
  ren.group.admin  = { members = [ ren.group.ops ]; };
  ren.group.deploy = { };

  ren.environment.prod    = { grants = [ ren.group.admin ]; edge = true; settings.kernel.channel = "lts"; };
  ren.environment.staging = { grants = [ ren.group.admin ren.group.deploy ]; inherits = ren.environment.prod; };

  ren.host.lb     = { environment = ren.environment.prod;    channel = ren.channel.stable; system = ren.system.x86_64-linux; addr = "10.0.1.1";  };
  ren.host.web-1  = { environment = ren.environment.prod;    channel = ren.channel.stable; system = ren.system.x86_64-linux; addr = "10.0.1.10"; settings.kernel.channel = "latest"; };
  ren.host.web-2  = { environment = ren.environment.prod;    channel = ren.channel.stable; system = ren.system.x86_64-linux; addr = "10.0.1.11"; };
  ren.host.stage  = { environment = ren.environment.staging; channel = ren.channel.edge;   system = ren.system.x86_64-linux; addr = "10.0.2.10"; };
  ren.guest.ci    = { environment = ren.environment.staging; channel = ren.channel.stable; system = ren.system.x86_64-linux; addr = "10.0.2.20"; on = ren.host.stage; };
  ren.mac.studio  = { environment = ren.environment.staging; channel = ren.channel.stable; system = ren.system.aarch64-darwin; addr = "10.0.2.30"; };
  ren.phone.pixel = { environment = ren.environment.staging; channel = ren.channel.stable; system = ren.system.aarch64-linux; };
  ren.home.alice-laptop = { user = ren.user.alice; channel = ren.channel.edge; system = ren.system.x86_64-linux; };

  ren.user.alice = { groups = [ ren.group.ops ]; phone = true; };    # admin through the closure
  ren.user.bob   = { groups = [ ren.group.deploy ]; };

  ren.db.primary.zone = "eu";
  ren.region.eu.zone  = "eu";
  ren.replica.r1      = { db = ren.db.primary; region = ren.region.eu; };

  # ══ CHANNELS — data (gen-aspects `channel`); at = emitters (default any), to = e: receivers ══
  ren.channels = {
    backends     = { fold = list;  at = ren.kinds.host;
                     to = e: and [ ren.kinds.host (when (r: same r.host.environment e.host.environment))
                                   (not e) (not ren.aspects.nginx) ]; };
    devices      = { fold = set;   at = ren.kinds.user;    to = e: and [ ren.kinds.user (when (r: same r.user e.user)) (not e) ]; };
    records      = { fold = attrs; at = ren.kinds.machine; to = _: ren.environment.prod; };
    deployment   = { fold = one;   at = metal;             to = e: e; };
    scrape       = { fold = list;  at = ren.kinds.replica; to = _: ren.host.lb; };
    overlays     = { fold = list;  at = ren.kinds.fleet;   to = _: ren.kinds.machine; };
    persist      = { fold = set;   at = anyOf [ ren.kinds.host ren.kinds.user ]; to = e: e.host; };
    flake-inputs = { fold = attrs; to = _: ren.fleet.main;          # no `at`: any scope emits
                     into = { ... }: inputs': { flake-file.inputs = inputs'; }; };
    tags         = { fold = set;   to = e: e; };

    # channels with `into`: data collectors (not module systems, so not classes)
    packages     = { fold = attrs; at = ren.kinds.system; to = e: e;
                     into = { system, ... }: pkgs': { packages.${system.name} = pkgs'; }; };
    colmena      = { fold = attrs; at = metal; to = _: ren.fleet.main;          # fed by the nixos class
                     into = { ... }: nodes: { colmenaHive = inputs.colmena.lib.makeHive
                       ({ meta.nixpkgs = inputs.nixpkgs.legacyPackages.x86_64-linux; } // nodes); }; };
    age-manifest = { fold = attrs; at = metal; to = _: ren.fleet.main;          # fed by the nixos class
                     into = { ... }: m: { ageManifest = m; }; };
  };

  # ══ ASPECTS — `at` activates; no `at` = only where included ═══════════
  ren.aspects = {

    base = {
      at      = ren.kinds.machine;
      os      = { machine, overlays, ... }: { networking.hostName = machine.name; nixpkgs.overlays = overlays; };
      records = { machine, ... }: { ${machine.name} = machine.addr; };
    };
    deploy-record = {
      at         = metal;
      deployment = { host, tags, ... }: { address = host.addr; user = "deploy"; inherit tags; };
    };

    hm-module = {                                                   # bundle: each key lands where its class lives
      at     = ren.kinds.machine;
      nixos  = { host, ... }: { imports = [ host.channel.home-manager.nixosModules.home-manager ]; };
      darwin = { mac, ... }:  { imports = [ mac.channel.home-manager.darwinModules.home-manager ]; };
    };
    secrets = { at = ren.kinds.host;
                nixos.imports = [ inputs.agenix.nixosModules.default ];
                flake-inputs  = { ... }: { agenix.url = "github:ryantm/agenix"; }; };

    vm      = { at = ren.kinds.guest;
                nixos.imports = [ inputs.microvm.nixosModules.microvm ];
                flake-inputs  = { ... }: { microvm.url = "github:microvm-nix/microvm.nix"; }; };
    vm-host = { at = and [ metal (has ren.kinds.guest) ]; nixos.imports = [ inputs.microvm.nixosModules.host ]; };

    unstable-overlay = {                                           # a function value: wrap it in `{ ... }:`
      at       = ren.fleet.main;
      overlays = { ... }: final: prev: { inherit (inputs.nixpkgs-unstable.legacyPackages.${prev.system}) helix; };
    };

    # ── cross-scope by predicate ──
    ssh-agent = { at = and [ ren.kinds.user (within ren.kinds.machine) ]; homeManager.services.ssh-agent.enable = true; };
    docker    = { at = and [ ren.kinds.host (has ren.user.bob) ];   # the hosts bob lives on
                  nixos.virtualisation.docker.enable = true;
                  persist = { ... }: "/var/lib/docker"; };
    htop      = { at = and [ ren.user.alice (within ren.host.web-1) ]; homeManager.programs.htop.enable = true; };

    desktop = { at = ren.host.stage; nixos.services.xserver.enable = true; };
    dock    = { at = ren.kinds.mac;  darwin.system.defaults.dock.autohide = true; };
    tiling  = { at = ren.kinds.user;                              # lands only on mac users
                homeDarwin.programs.aerospace.enable = true; };

    motd       = { at = ren.kinds.machine; os.users.motd = "managed by ren"; };
    motd-short = { os.users.motd = "ren"; };                        # included only
    quiet      = { at = ren.host.web-2; excludes = [ ren.aspects.motd ]; includes = [ ren.aspects.motd-short ]; };

    http-port = { at = and [ ren.kinds.host ren.aspects.nginx ];    # an aspect ref = "active here"
                  nixos.networking.firewall.allowedTCPPorts = [ 80 ]; };

    kernel = {
      at    = ren.kinds.host;
      nixos = { host, environment, pkgs, ... }:
        let k = first [ host.settings.kernel.channel environment.settings.kernel.channel
                        (environment.inherits.settings.kernel.channel or null) "latest" ];
        in { boot.kernelPackages = if k == "lts" then pkgs.linuxPackages else pkgs.linuxPackages_latest; };
    };

    impermanence = {
      at    = metal;
      nixos = { persist, ... }: {
        imports = [ inputs.impermanence.nixosModules.impermanence ];
        environment.persistence."/persist".directories = persist;
      };
    };

    dev = {
      at          = anyOf [ ren.kinds.machine ren.kinds.user ];
      os          = { programs.git.enable = true; };
      homeManager = { programs.git.enable = true; };
    };

    sync = {
      at          = ren.kinds.user;
      devices     = { parent, ... }: parent.name;
      persist     = { user, ... }: "/home/${user.name}/.local/state/syncthing";
      homeManager = { devices, parent, lib, ... }: {
        services.syncthing.enable           = true;
        services.syncthing.settings.devices = lib.genAttrs devices (_: { });
        services.syncthing.tray.enable      = is ren.aspects.desktop parent;   # same `is` as everywhere
      };
    };

    tools = { at = ren.kinds.system;
              packages = { system, ... }: { inherit (inputs.nixpkgs.legacyPackages.${system.name}) hello; }; };

    dns = { at = ren.environment.prod;
            terraform = { records, lib, ... }: {
              resource.cloudflare_record = lib.mapAttrs (_: addr: { value = addr; type = "A"; }) records; }; };

    replica-scrape = { at = ren.kinds.replica;
                       scrape = { db, region, replica, ... }: { job = replica.name; target = "${db.zone}.${region.zone}:9090"; }; };

    # ── included only ──
    nginx = { nixos.services.nginx.enable = true;
              tags     = { ... }: "web";
              backends = { host, ... }: host.addr;
              persist  = { ... }: "/var/lib/nginx"; };
    haproxy.nixos = { backends, lib, ... }: { services.haproxy.enable = true;
      services.haproxy.config = lib.concatMapStrings (a: "  server ${a} ${a}:80 check\n") backends; };
    monitoring.nixos = { scrape, ... }: {
      services.prometheus.scrapeConfigs = map (j: { job_name = j.job; static_configs = [ { targets = [ j.target ]; } ]; }) scrape; };

    # ── activators ──
    lb  = { at = ren.host.lb; includes = [ ren.aspects.haproxy ren.aspects.monitoring ]; };
    web = { at = anyOf [ ren.host.web-1 ren.host.web-2 ren.host.stage ]; includes = [ ren.aspects.nginx ]; };
  };
}
```

## Evaluation order (strata)

| stratum | computes | reads | a cycle inside it is |
|---|---|---|---|
| 0 scopes | `below`/`spawns` tree, `is` (subkind), `parent`, `within`, `has K` | instances, `same` (id_hash, needs no scope), `when` on bindings | impossible: gen-scope refuses a cyclic or self-naming `below` |
| 1 activation | `at`, `includes`, `excludes`, `has` in predicates | stratum 0 | an eval error "not stratified" if it passes through `not`/`excludes` |
| 2 content | aspect values, channels (`fold`), `is P x`, `aspects` | strata 0–1, channels (lazy) | Nix infinite recursion: never a wrong value |
| 3 classes | `into`: forwards, flake outputs | strata 0–2, and `outputs` of classes this branch does not forward into | an eval error: a static check on the class graph |

`docker`'s `has ren.user.bob` sits in stratum 0. It reads the same spawns result that put bob there, so it can't drift from the grant rule.

## Expected result (new and changed rows only; v25's other rows stand)

| capability | must appear | must **not** appear |
|---|---|---|
| `fold = one` | `deploy.nodes.lb.hostname = "10.0.1.1"` | `deployment` handed to `into` as a list; two `deployment` emitters on one host evaluating |
| `fold = list` order | lb's haproxy lists web-1, then web-2 (scope-path order), on every eval | order depending on attribute or include order |
| guest channel | ci (`stable`) built with stable pkgs inside stage (`edge`) | ci silently built with stage's `edge` pkgs |
| chained forward | bob's HM in ci → ci's nixos → stage's `microvm.vms.ci.config` | bob's ci home in stage's own `home-manager.users` |
| darwin + `os` | `darwinConfigurations.studio`: hostName, motd, git, dock; alice + bob HM under darwin | studio in `nixosConfigurations` or `colmena`; `kernel` or `impermanence` on studio |
| standalone home | `homeConfigurations.alice-laptop` (edge HM): git, syncthing | ssh-agent in alice-laptop (not `within machine`) |
| host-qualified | htop in alice's home on web-1 only | htop for alice on lb/web-2, or for bob anywhere |
| substitute | web-2 motd = "ren"; others "managed by ren" | both motd values on web-2 (a merge conflict) |
| `has` | docker on stage and ci (bob lives on both) | docker on prod hosts; docker that tracks a hand-copied grant |
| `parent` | alice's syncthing devices = lb, web-1, web-2, stage, ci, studio, pixel, alice-laptop (minus the scope's own parent) | branching on `host ? null` in content |
| per-system | `packages.{x86_64-linux,aarch64-linux,aarch64-darwin}.hello` | `packages` keyed by host |
| overlays | every machine has the helix overlay | the overlay applied twice on ci (once through stage) |
| impermanence (`set`) | stage persists `/var/lib/nginx`, `/var/lib/docker`, alice's and bob's syncthing dirs, once each | ci's docker dir on stage; a duplicate path |
| name uniqueness | — | `ren.host.ci` and `ren.guest.ci` both evaluating |
| output merge | — | two scopes writing different `nixosConfigurations.lb` evaluating |
| content-function rule | — | a bare `final: prev:` emission evaluating as content |
| hmPlatforms (`homeDarwin`) | aerospace in alice's and bob's homes on studio only | aerospace in any linux, phone or standalone home |
| tags = emission | colmena tags for stage include `web` (nginx emits it) | a `tags` key reserved by Ren |
| flake-file | `flake-file.inputs.{agenix,microvm}` written once, a top-level option beside `nixosConfigurations` | an input listed by an aspect that is not active; two aspects giving `agenix` different urls evaluating |
| recursive `attrs` | `deploy.nodes.{lb,web-1,web-2,stage}` and `colmena.{…}` merged from four host scopes; `agenix = { url; inputs.nixpkgs.follows; }` from two aspects that agree on `url` | a conflict error between hosts for the top-level `deploy` key |
| `anywhere` | a `flake-inputs` emission from an aspect `at = ren.fleet.main` reaches `flake-file.inputs` | root-scope emissions dropped because `within` excludes the root |
| `attrs` in `into` | `packages.x86_64-linux` built from two aspects' attrsets | two aspects giving different `hello` derivations evaluating (v27's `mergeAttrsList` kept the last) |
| per-branch stratum 3 | the standalone-home branch reads `outputs.nixosConfigurations.<h>.config` (Den `osConfig`) | the `within host` branch reading `outputs.nixosConfigurations` evaluating: it forwards into `nixos`, so that's a cycle |
| parent-side `spawns` | users on lb, web-*, stage, ci, studio from `usersOn`; alice on pixel; alice on alice-laptop | a `spawns.user` on a kind whose `below` lacks `user` evaluating (gen-scope refuses it) |
| no guest in a guest | — | `ren.guest.x = { on = ren.guest.ci; }` producing a scope (guest's own `below` has no `guest`) |
| identity without scopes | `closure` and `granted` compare groups with `same` | identity that needs a group scope (groups never spawns) |
| `is P x` on the path | stage users' syncthing tray on (desktop active on `parent`) | `is` picking one of alice's other scopes |
| `anyOf` | — | Ren exporting `any` (gen-select's tombstone; clashes with `lib.any`) |
| channel `into` | `packages.<sys>.hello` from the `packages` channel; `colmenaHive` and `ageManifest` fed by the nixos class | `tools.packages` evaluated as a module (`deferredModule`) |

> VIC:

## Gen mapping

Read in gen's code at origin/main (gen bcbc5ca, gen-scope adc5180, gen-select 42a09ef, gen-view b3cb176, gen-delivery d4095af, gen-aspects 1847f11, gen-schema 2a9f618, gen-bind 707838a, gen-assemble 4f757c8, gen-settings, gen-graph). Nothing was evaluated.

| Ren construct | gen owner | status |
|---|---|---|
| `below` / `spawns` (parent side, keyed by child kind) | gen-scope `mkKind { name; below; spawns; }` (cascade.nix:425-433): same direction, same keying | direct. The builder sees `{ id, parent, decls, type }`, so passing Ren's scope bindings is glue |
| several parents | gen-scope: each parent kind lists `user` in its own `below`. Spawned ids must be minted `parent/child` (P is a partial function, build-nodes.nix:244) | glue (ids) |
| channels with `into` | gen-delivery `realize` with one terminal per channel; gen-aspects keeps them `raw` | glue |
| `is` subtyping | gen-select `subkind` (constructors.nix:154) matches a kind or its ancestors; gen-schema kinds | glue; whether a scope can bind under two kind names is UNVERIFIED |
| `within`, `has`, `parent` | gen-select `within` / `has` / `parentMatches` (match.nix:122/119/125) | direct |
| `anywhere` | gen-select `star` (constructors.nix, match.nix:100: always true) | direct |
| fold laws as functions in `into` | the same Ren glue as channel folds | glue |
| per-branch stratum-3 check | gen-graph `lib/order.nix` over the class graph | direct (file exists; not read further) |
| `and anyOf not`, kind/instance refs | gen-select `and` / `anyOf` / `not` / `kind` / `entity` | direct, same names |
| `when f` | gen-select `when` (called `fn id ctx`) | 1-line adapter |
| `same` | gen-schema `id_hash` identity | direct |
| typed strict kinds, ref fields | gen-schema `mkInstanceRegistry`, `mkStrictModule` | direct |
| aspects, `includes`, class vs channel keys | gen-aspects `includes`, `keyCategory` (class vs channel) | direct |
| `excludes` | none in gen-aspects; gen-rules `conditionalEdge { unless }` and gen-program `suppress` guard an include | GAP: nothing removes an existing include |
| `has` with stratification, negative-cycle error | gen-program (well-founded and stable-model oracles) | UNVERIFIED |
| channels | gen-view movement works receiver-side over graph paths; emitter-parameterised `to` is a filter | glue |
| `fold` laws | `list` = gen-assemble positional content fold; `set`/`attrs`/`one` not found as named folds | glue |
| `first` cascade | gen-settings `lib/resolve.nix`: positional authority, no strength lattice (:7) | direct, reversed order |
| group closure | gen-graph `lib/fixpoint.nix` | direct (file exists; not read further) |
| class DAG, stratum-3 check | gen-graph `lib/order.nix` | direct (file exists; not read further) |
| content args | gen-bind `wrapAll` with bindings ∪ channels | direct |
| classes → outputs | gen-delivery `project` / `realize`, one terminal per class | glue |
| forwarding | none; two-pass through gen-delivery's `extraModules` inlet | GAP |

The two gaps, forwarding and `excludes`, are where Ren would push gen forward rather than just use it.

## Den coverage

Every user-facing pattern in `~/hk/den/docs/src/content/docs`, read in full by 4 readers this session. Cross-flake namespaces, angle brackets and Den tooling are out of scope.

| Den pattern (doc) | Ren |
|---|---|
| aspect class bundle (`explanation/aspects:21`) | one aspect with several class keys (`hm-module`), `at = anyOf [ … ]` |
| `includes` / nested aspect / `._` children (`guides/configure-aspects:116-225`) | `includes = [ … ]`; a group is a plain Nix attrset |
| inline fn include (`explanation/aspects:52`) | an anonymous aspect inside `includes` |
| parametric `{ host, user }:` aspect, arg-shape gating (`explanation/parametric:20-67`) | content args = scope bindings; activation is `at`, never the arg shape |
| class module forms `{ host, config, pkgs, ... }` (`explanation/class-modules:25-97`) | content fn args = bindings, channels and module args |
| `excludes`, constraints `exclude`/`substitute`/`filterBy` (`explanation/structural:160-215`) | `excludes`; substitute = `excludes` + `includes` (aspect `quiet`) |
| `"tux@igloo"` host-qualified aspect (`explanation/entities:54`) | `at = and [ ren.user.alice (within ren.host.web-1) ]` |
| `provides.to-users`, `provides.<user>` (`guides/mutual:88-91`) | `at = and [ ren.kinds.user (within ren.kinds.machine) ]` |
| `provides.to-hosts`, `provides.<host>` (`guides/mutual:80-83`) | `at = and [ ren.kinds.host (has ren.user.bob) ]` |
| `{ user, ... }:` nixos per user on host (`explanation/where-config-lands:168`) | a class `at` the user scope (`homeManager`), or a host aspect that maps over the host's users |
| `host-aspects` battery (`reference/batteries:133`) | home aspect `at` the user, reading `is ren.aspects.desktop parent` in content |
| `hasAspect`, `.forClass`, `host.aspects` (`explanation/structural:28-151`) | `is P x`, an aspect ref as predicate (`ren.aspects.nginx`), `has` |
| `den.hosts` / `den.homes` / per-user `classes` (`reference/schema:108-236`) | kinds `ren.kinds.host`, `ren.kinds.home` with instances `ren.host.<name>`; a per-user class = a class `at` the user kind with `when` |
| schema extend, freeform, `strict` (`explanation/entities:117-251`) | kinds are always typed and strict; freeform is not allowed |
| `den.schema.<kind>.includes` (`explanation/entities:117`) | aspect `at = ren.kinds.<kind>` |
| `den.default` (`guides/configure-aspects:260`) | aspect `at = anyOf [ every kind ]` |
| `fleet` grouping kind (`explanation/fleet:244`) | `ren.kinds.fleet` |
| `policy.resolve.to`, `resolve` enrich (`reference/policies:39-53`) | `below` and `spawns`; enrich = a kind field or a value computed in `spawns` |
| `policy.include` / `when` / `for` / `mkPolicy` (`reference/policies:55-274`) | `at` predicates |
| `policy.provide` / `route` / `deliver` / `forward` battery / `forwardTo` (`reference/policies:71-151`) | class `into` returning a class key (it forwards) |
| `policy.instantiate`, `intoAttr`, `intoAttr = [ ]` (`reference/output:26-101`) | `into` returns top-level option keys; no key = no output (guest) |
| host `instantiate` override, patched nixpkgs (`guides/nixpkgs:243`) | `channel` kind instance data (`ren.channel.stable`) used by `into` |
| quirk declare / produce / consume (`reference/quirks:14-105`) | `ren.channels` + a key in an aspect (emission) + a channel arg in content |
| `pipe.filter/transform/fold/append/for/as` (`reference/quirks:140-216`) | plain Nix on the channel value, plus channel `fold` |
| `pipe.to [ aspects ]` (`reference/quirks:297`) | `to = e: and [ … ren.aspects.nginx ]` |
| `pipe.collect` / `collectAll` / `broadcast` / `expose` (`guides/quirks-cross-scope:89-361`) | `to` predicates: same env (`when` + `same`), any (`ren.kinds.machine`), same instance (`e`), ancestor (`e.host`) |
| `pipe.withProvenance` (`reference/quirks:321`) | emit the source in the value (`{ name; addr; }`) |
| quirk `{ config, ... }` producer thunk (`explanation/quirks:237`) | not allowed in content; read realized config only in `into` through `outputs` |
| settings: reservedKeys, required, mkDefault/mkForce, user settings (`guides/aspect-settings`) | `settingsT` per kind; no default = required |
| collision policy `den-wins`/`class-wins` (`reference/aspects:185-224`) | NixOS module merge; a name clash with a module arg is an eval error |
| batteries: define-user, hostname, primary-user, user-shell, unfree, insecure, autologin, wsl (`reference/batteries`) | ordinary aspects shipped by a library |
| `os`, `user`, hjem, maid, custom classes (`guides/custom-classes`) | `ren.classes`; `os` is one class with a list of branches |
| flake outputs per system: packages/apps/checks/devShells, `flake` class (`guides/flake-outputs`) | `system` kind + `packages` channel with `into` |
| ACL environments (`guides/acl-environments`) | `group` kind + `closure` + `granted` |
| overlays, `useGlobalPkgs`, unstable channel (`guides/nixpkgs`) | `channel` kind; overlays = the `overlays` channel, gated by `when` |
| standalone home, `user@host` home (`guides/standalone-home-manager`) | `home` kind + `homeManager` class branch |
| microvm `resolve` + `provide` (`tutorials/microvm:145-186`) | `guest` kind (`is = ren.kinds.host`) + `nixos` class branch at the guest that forwards |
| terranix / k8s `instantiate` (`tutorials/terranix-demo`, `case-study-kubernetes`) | value-gated class (`terraform`, `when`); a cluster kind + class per system |
| impermanence persist collector (`tutorials/case-study-disks-impermanence:280-352`) | `persist` channel, `fold = set` |
| `meta`, fixed-point `config` self-ref (`guides/configure-aspects:290-365`) | Nix `let` / `rec` in the aspect's file |
| nh apps, diagrams, policyInspect, denTest, import-tree | tooling |

## Den templates and CI tests vs Ren

Sources: every `.nix` file in `~/hk/den/templates`, read in full by 9 readers (all report 100% coverage):
- 13 templates, 154 files;
- CI, 288 files.

The table lists only patterns not already in **Den coverage** above.

| Den pattern (source) | Ren |
|---|---|
| hmPlatforms, hmAlias (`ci/…/hm-platform-forward.nix:22`, `forward-alias-class.nix:5`) | sub-class forwarding in place (`homeDarwin`); HM's own `osConfig` arg |
| roleClass: a key named after a role, applied when host and user share it (`guides/custom-class-examples:109`) | `ren.classes = lib.genAttrs roles (r: { at = and [ ren.kinds.user (when (s: shares r s)) ]; into = { ... }: ms: { nixos.imports = ms; }; })` |
| nixClass: one key to nixos and homeManager `nix.settings` (`custom-class-examples:166`) | a class list with two branches forwarding to `nixos.nix.settings` and `homeManager.nix.settings` |
| guarded forward, persys, gitClass: guard on `options ? x` or `config.programs.git.enable` (`ci/…/guarded-forward.nix:24`, `route-intopath-conditional-leak.nix:42`) | guard in stratum 0/1 (`at`, `has`), or `lib.mkIf cond value` around a config *value* inside the class. **Not** `options ? x` around a module: `imports` cannot depend on `options`/`config` (the module system recurses), and `m` is usually a function |
| `deliver` modes merge / nest / verbatim, dynamic `intoPath` (`ci/…/deliver.nix:46-247`, `dynamic-intopath.nix:5`) | what `into` returns: `ms` as imports (merge), under a path (nest), or into a sub-eval (verbatim, as the guest does) |
| isolated entity + `collectSubtree` + `appendToParent` (`ci/…/route.nix:211`, `entity-isolation.nix:42`) | guest kind + guest class; nothing leaks, because content lands only in its own scopes |
| microvm runners, nvf packages from a parametric aspect (`microvm/microvm-runners.nix:10`, `nvf-standalone/…/den.nix:13`) | a `packages` class; an aspect is a value: `includes = [ (neovim { mine = true; }) ]` |
| terranix modules per host, flake-parts classes devshell/files/treefmt/nix-unit (`terranix-demo/…/terranix.nix:23`, `flake-parts-modules/…/classes/*.nix`) | one class each; `into` writes the top-level option (`devshells.default`, `files`, `nix-unit.tests`) |
| home `instantiate` with the host's `osConfig` (`ci/…/special-args-custom-instantiate.nix:6`) | the standalone-home branch reads `outputs.nixosConfigurations.<h>.config` (stratum 3). Legal only because the check is per branch: the `within host` branch forwards into `nixos` |
| `user@host` home synthesizes a host (`ci/…/standalone-home-host-context.nix:40`) | `home.on = maybe ren.kinds.host`; `when (s: same s.home.on ren.host.x)` |
| relationship fan-out `{ user, pet }`, transitive `{ pet, toy }` (`ci/…/relationship-fanout.nix:343,431`) | kinds `pet` (spawns under host) and `toy` (spawns under pet); an aspect `at = ren.kinds.toy` binds `pet` and `toy` |
| per-user parametric content stays per user; static content shared (`ci/…/issue-644-parametric-host-forward-per-user.nix:35`) | an aspect at user scope fires once per user scope; module key `<aspect>@<path>` |
| chained forward classes (`ci/…/issue-645-chained-forward-classes.nix:41`) | forwards chain (class → class → class), acyclic |
| same aspect in host and user schema includes, once per scope (`ci/…/relationship-fanout.nix:291`) | `at = anyOf [ host user ]`: one firing per scope |
| identical values merge, different values error (`ci/…/issue-674-identical-values-merge.nix:14`, `instance-collection-merge.nix:127`) | the `attrs` law for outputs and channels |
| named inline include identity, shared raw include dedup (`ci/…/nested-key-wrapper-identity.nix:221`, `shared-raw-include-splits.nix:17`) | module key `<aspect>@<scope path>`; an anonymous aspect in `includes` is keyed `<taker>/<index>` |
| exclude by string rejected (`ci/…/excludes-string-form-rejected.nix:13`) | `excludes` takes refs only; a string is a type error |
| exclude naming an aspect that never fires: a warning (`ci/…/unmatched-policy-exclude.nix:29`) | the same warning: an `excludes` that removes nothing |
| quirk named like a class (`den.quirks.nixos`): throws (`ci/…/pipes.nix`) | class and channel names are disjoint: eval error |
| `den.schema.conf`: options on every kind (`ci/…/doc-examples.nix:6`) | a shared `let` field set merged into each kind, or an abstract kind with `is` |
| enrich context with a flag (`isNixos`) via `policy.resolve` (`ci/…/policy-context-enrichment.nix:8`) | a kind ref (`ren.kinds.host` vs `ren.kinds.mac`) or a `let` predicate |
| `{ self, ... }` fires once at its registration scope (`ci/…/self-guard.nix:13`) | `at = ren.host.igloo` (instance ref) |
| noflake entry, npins, with-inputs (`noflake/default.nix:1`) | `ren.lib.mkFlake` is a module set; `evalModules` it without a flake; entry points: flakes (`mkFlake inputs module`), no flakes (plain `import` with locked `inputs`), flake-parts (`flakeModules.default`, option `fleet`), plain `lib.evalModules` (`lib.flakeModule`, option `fleet`), Gen modules (Ren only, the same `lib.flakeModule`) |
| `systems = builtins.attrNames den.hosts` (`fleet-demo/…/flake-parts.nix:4`) | `ren.system` instances |
| `includeIf` with fallback (`ci/…/fx-includeIf.nix:180`) | `a = { at = and [ K ren.aspects.sops ]; … }; b = { at = and [ K (not ren.aspects.sops) ]; … }` |
| exclude subtree vs `.global`, `filterBy` (`ci/…/fx-constraints.nix:266-688`) | `excludes` is subtree; global = an `excludes` on an aspect `at = ren.fleet.main`; filterBy = `excludes = lib.filter p (lib.attrValues ren.aspects)` |
| `_module.args.host` colliding with a den arg; `collisionPolicy` (`ci/…/class-module-partial-apply.nix:437-535`) | a binding or channel value name clashing with a module arg is an eval error; no policy knob |
| custom class with no route: throws (`ci/…/forward-to.nix:123`) | a key that names no class or channel: eval error |
| class key as a list of modules (`ci/…/fx-full-pipeline.nix:247`) | content may be a list; each element is one module in `ms` |
| den as a library with a custom domain (`ci/…/den-as-lib.nix:62`) | Ren's kernel has no domain names: classes and kinds are all user-declared |
| flake-level forward, per-host parametric packages (`ci/…/forward-flake-level.nix:5,166`) | a host class writing `packages.${system}.${"sw-" + host.name}` (attrs law merges hosts) |

### Den behaviours Ren refuses (by design)

| Den behaviour (source) | Ren instead |
|---|---|
| quirk value `{ config, ... }:` reads the producer's realized config, even cross-host (`ci/…/pipe-config-scope.nix:11`, `bprime-basedrain-crosshost.nix:39`) | content never reads config; read realized config only in `into` via `outputs` (stratum 3) |
| misplaced entity arg (`{ gadget, ... }:` with no gadget) is silently inert (`ci/…/relationship-fanout.nix:128`) | activation is `at`; a content arg with no binding is an eval error |
| homeManager content at host scope is silently inert (`ci/…/issue-609-host-scope-hm-leak.nix:17`) | an error if it lands in none of the aspect's scopes |
| `hasAspect` inside `includes` is an infinite recursion (`example/…/hasAspect-examples.nix:109`) | an aspect ref in `at` is stratified; a cycle is a named eval error |
| `policy.resolve.shared` vs isolated scopes, `mkPolicy` claimants (`ci/…/policy-resolve-shared.nix`) | no policies: `spawns` makes scopes, predicates select |
| namespaces, angle brackets, import-tree, diagrams, denTest | outside Ren (gen-link, tooling) |

## Den feature requests vs Ren

Sources:
- denful/den: 19 open issues, read in full; 149 open discussions, with Ideas read in full and Help/FAQ skimmed.
- `~/Downloads/el.txt`, the Matrix log: **read in full**, all 35 390 lines, by 12 readers.

`#N` is an issue or discussion; `L<line>` is a Matrix log line. Repeats are merged.

### Already expressible in Ren (no change)

| ask | Ren |
|---|---|
| per-aspect flake inputs: #348, #336, L17109, L20140, L21482, L33338, L33346; fetch only active aspects' inputs: L20814 | `flake-inputs` channel + `flake-file` class. The regenerated `flake.nix` lists only active aspects' inputs; activation changes need a regeneration step |
| user content must not change the shared host: #694; host app → all users vs user app → one user: L535, L4888, L5655, L29994 | no provides-to; content lands only in the aspect's own scopes; `within` / `has` |
| host↔user both ways, opt-in: #450, L1110, L1857, L5676, L6802, L7509, L18917, L18929, L25830, L25875, L27963, L28063 | predicates: `within`, `has` (`ssh-agent`, `docker`, `htop`) |
| hmLinux / hmDarwin / hmAarch64 forwards: L26816, L34138, L34189, L34191 | a sub-class forwarding in place (`homeDarwin`) |
| aspect metadata, tags: L5141, L28728, L28734, L28835 | `tags` is just an emission (fold `set`); `deployment.tags = tags` (not `meta`: gen-aspects reserves it) |
| `den.hosts.<h>.includes` dropped: #663; `include` typo silent: L14871; early shape errors: L27758, L35195, L31077 | strict kinds; a key that is not a class or channel, or lands nowhere, is an eval error |
| `os` to systemManager: #718; finix: #662; disko: L30402; timezone for nixos+darwin: L24576 | an `os` class branch; a class per builder |
| nix-on-droid: #517; terranix, per-host plan/apply: #115, L9418, L15871, L16194, L16263 | `droid` class; `terraform` class (env or host) |
| custom entity kinds, k8s clusters, identities, domains: #701, L1233, L1312, L7046, L9659 | `ren.kinds.*` + a class |
| service discovery, vhost → proxy, contributes-to, host A reacts to host B: L1241, L1891, L3626, L8626, L8666, L8718, L10555, L10638, L13153, L14353, L15580, L22851, L17277, L26453, L28072 | channels with `from`/`to` predicates; `is P x` |
| `hasAspect` presence, include when A and B: L2011, L4753, L4759, L4804, L19798, L20902, L25924, L27618, L28376 | an aspect ref in `at` (stratified), `is P x` in content |
| `includedBy`, leaf-to-root membership, of.host: L16608, L18542, L25436, L33967 | that is what `at` is |
| relation that is not an instantiation: L25801 | channels and predicates never spawns; only `spawns` creates scopes |
| exclude an inherited aspect / default on one host or user: L1432, L18502, L21348; variant swap: L1434 | `excludes`; substitute = `excludes` + `includes` |
| one default for host users and standalone homes: #205, L1513; `user@host` homes: #206, L12497, L24023, L26159, L26610 | `at = ren.kinds.user`; the `home` kind, plus a field `on = maybe host` |
| impermanence per aspect: #590, L23751, L31027 | `persist` channel (fold `set`) + `has` |
| recursive groups, ACL, admin groups from other aspects: L1316, L9646, L27846, L28483 | `group` kind + `closure`; a `groups` channel |
| global include (sops everywhere): L1244; stateVersion battery: L452 | an aspect `at = ren.kinds.machine` |
| register a user on all hosts, users first-class: L18763, L18807, L19693, L26396, L29019, L30697 | user `spawns f` over `ren.user`; the user kind is host-independent |
| list a host's users, sync users: L32162, L33144 | `has ren.kinds.user`, or a channel `to = e: e.host` |
| shared options for nixos + HM, context config from anywhere: L1167, L3370, L3403, L3454, L30900 | kind fields read through bindings (`host.settings`, `user.*`) |
| per-aspect settings namespace: L6027, L25261; package-typed options: L8355, L8468, L28282 | `settingsT`; a field `t.functionTo t.package` |
| per-host channel, patched nixpkgs: L30125, L30448, L30542; per-aspect pkgs: L1640, L4487, L4549, L4584, L13086 | the `channel` kind; content may close over another channel's pkgs |
| lib/inputs/self'/custom args anywhere: L1669, L9955, L9960, L9986, L11728, L13070, L13096, L13255, L24963, L24975, L30247, L32095 | content args = bindings ∪ channels ∪ module args; `inputs` is in scope |
| devshell, emacs and maid-list classes, adapters: L858, L4726, L5968, L6528, L6770, L7330, L18218, L32123 | a class whose `into` maps `ms` into any option |
| one `pkgs` aspect adapting by include site: L23078; per-host package subsets: L23310 | a `pkgs` class list (host → systemPackages, user → home.packages); `includes` subsets |
| glob / all children: L14184, L14194, L14212, L14214, L20718, L20743, L21711 | `includes = lib.attrValues ren.aspects.<group>` |
| colmena, deploy-rs, nh class, fleet deploy: L15847, L15851, L15855, L22308, L24606 | `deployment` channel (fold `one`) read by several classes |
| quirks into a fleet file, custom top-level outputs: L24456, L32574, L32688 | a channel `to = _: ren.fleet.main` + a class |
| checks class, terraform validate: L32201, L32305, L32410 | a `checks` class at `system` |
| secrets declared per aspect, agenix secrets.nix: L21088, L32512, L32515 | a `secrets` channel to the fleet + a class writing the file |
| osConfig of hosts from the flake level: L20831, L21752 | `outputs` (stratum 3) |
| config invariants across hosts: L22634; assert/throw accounts: L32175 | a fleet class reading channels or `outputs` and throwing |
| deterministic ids, ports, IPs: L19799, L19824, L19834, L19859, L19990 | a `let` allocator over sorted `ren.<kind>` names (stratum 0); a collision is an eval error |
| one host in two fleets: L15822 | the same instance on two spawns paths (`anyOf [ spawns … ]`) |
| per-system outputs from one host (vm): L26519 | a host class returning several outputs |
| specialisations, vmVariant-only config: #691, L18129, L18725 | a `variant` kind under host + a class forwarding to `nixos.specialisation.<n>.configuration` |
| dedup when two users include the same nixos: L4877; dedup by args: L6414; provenance: L24628 | module key `<aspect>@<scope path>`; `attrs` merge law |
| registry vs activation, policies as values, composition, order-insensitive: L9197, L11117, L14482, L14758, L14790 | refs are values; `and anyOf not`; `at` activates; folds are order-free (except `list`, by scope path) |
| shared predicates, typed guards (isDarwin): L12577, L12590, L18476 | `let` predicates (`metal`); kind refs (`ren.kinds.mac`); typos are eval errors |
| reuse existing nix modules as aspects: L16853 | `nixos = import ./hardware.nix;` |
| `pipe.to` an entity, pipe default, `pipe.as`: L15095, L15097, L17329 | `to` predicate; empty channel value; an aspect emitting a new channel |
| drop `each` from forward: #476; vic's wishlist L752-761 | a forward is a returned key |

### Possible, but Ren would need a change

| ask | change needed |
|---|---|
| patch an attr of a third-party aspect or its output before merge: #443, L4923, L6072 | an override form `ren.aspects.x.override = f`; `excludes` + `includes` covers only whole-aspect swaps |
| nested aspect groups (`dev.cli.bat`) without `provides`: L5146, L5153, L5280, L6019, L19401 | a rule telling a group (no class, channel or reserved keys) from an aspect |
| one aspect defined in several files, content fns included: L11448 | a merge law for content functions (merge their results) |
| a schema on channel values: L30891 | a channel `type` key, checked at emission |
| use Ren aspects outside Ren: #569 | `ren.lib.moduleOf aspect scope` |
| priority by specificity (`tux@igloo` over `tux`): #686 | instance ref > kind ref, mapped to `mkOverride` |
| option docs from the kinds: L9533 | a class that reads `ren.kinds` as data |
| explain, trace and inspect resolution: #103, L8976, L12332, L14679, L14726, L21366, L31082, L31202 | an inspector over the strata (why active, where landed) |
| diagrams, TUI, web UI, LSP, SQL over infra: L1541, L3558, L10982, L16878, L20897, L24400, L28676 | tooling over the same strata data |
| namespaces, batteries store, versioning, many projects: #158, #538, L10726, L10857, L11570, L28716, L29049 | gen-link (cross-flake), deferred |

### Not in Ren, by design or outside its reach

- Declaring a host's users inside an aspect (L33868): existence is `spawns`, stratum 0.
- Real-host config from a standalone home (L1857): a home has no host scope.
- Clan interop (L176, L22344), angle brackets and import-tree headers (L15404, L18008, L20961): external or tooling.
## Open

- **v29.A: parent-side `spawns` scatters "where users come from" over five kinds.** That's the cost of Gen's direction. `usersOn` keeps the rule itself in one place; only the wiring is per parent. If that reads worse to you, a child-side form needs new words (`under`, `picks`), not Gen's `below`/`spawns` with the meaning reversed.
- **v29.A: channels with `into` vs a third noun.** Folding the data outputs into `channels` keeps the noun count at v29's. The alternative is a separate noun for data outputs, which is clearer but adds a word.

- **`machine` adopted (vic, v26).** It is the abstract kind for darwin and the `os` class; `host` and `mac` are its subtypes.
- **`parent` vs naming the kind.** `parent` makes `devices` one line, but an aspect that needs "the host" specifically should still bind `host`. `parent` is for code that is generic over parent kinds.
- **Overlay on guests.** ci gets `nixpkgs.overlays` from `base` inside its own config, and its pkgs come from its channel. Whether microvm's `vms.<n>.pkgs` composes with the guest's `nixpkgs.overlays` is a microvm.nix question, not checked.
- **Den items still not shown:** namespaces from another flake (gen-link), per-user classes (hjem/maid), wsl. Each is a class plus a predicate; none needs new surface.
