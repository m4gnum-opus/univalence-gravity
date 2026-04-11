# Development Environment Setup

This guide walks through setting up a complete development environment for the **Univalence Gravity** repository on Linux (including WSL/Ubuntu). Two toolchains are needed:

1. **Agda 2.8.0 + `agda/cubical`** — for type-checking the formal proofs
2. **Python 3.12 + NetworkX/NumPy** — for the oracle pipeline (`sim/prototyping/`)

Both are required. The Agda side verifies all machine-checked theorems; the Python side generates the large auto-generated modules that Agda then checks.

---

## 1. System Dependencies

Install core build tools and C libraries needed by GHC and Agda:

```bash
sudo apt update
sudo apt install curl build-essential zlib1g-dev libffi-dev libgmp-dev -y
```

## 2. Haskell Toolchain (GHCup)

Agda is a Haskell program distributed via Cabal. Install the Glasgow Haskell Compiler and Cabal through [GHCup](https://www.haskell.org/ghcup/):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
```

Accept the defaults. When finished, **restart your terminal** (or run `source ~/.bashrc`) so `ghc` and `cabal` are on your `PATH`.

Verify:

```bash
ghc --version    # expect 9.6.x or 9.8.x
cabal --version  # expect 3.14.x
```

> **Recorded stable versions (April 2026):** GHC 9.6.7, Cabal 3.14.2.0

## 3. Agda 2.8.0

Install Agda via Cabal. This compiles from source and takes **15–30 minutes** depending on your machine:

```bash
cabal update
cabal install Agda-2.8.0
```

The executable lands in `~/.cabal/bin/agda`. Ensure it is on your `PATH`:

```bash
export PATH="$HOME/.cabal/bin:$PATH"
```

(Add the line above to `~/.bashrc` or `~/.profile` for persistence.)

Verify:

```bash
agda --version   # expect: Agda version 2.8.0
```

## 4. Cubical Library

Clone the `agda/cubical` library and register it with Agda:

```bash
mkdir -p ~/agda-libs
cd ~/agda-libs
git clone https://github.com/agda/cubical.git
```

Create (or append to) the Agda configuration files:

```bash
mkdir -p ~/.agda
echo "$HOME/agda-libs/cubical/cubical.agda-lib" >> ~/.agda/libraries
echo "cubical" >> ~/.agda/defaults
```

> **Important:** Agda does **not** expand shell variables like `$HOME` inside its config files when read at runtime — but the `echo` command above expands `$HOME` at write time, producing the correct absolute path. If you edit `~/.agda/libraries` by hand, use a full absolute path (e.g. `/home/yourname/agda-libs/cubical/cubical.agda-lib`).

## 5. Editor Setup (VS Code)

### 5a. Native Linux

1. Install [Visual Studio Code](https://code.visualstudio.com/).
2. Open the Extensions panel (`Ctrl+Shift+X`), search for **agda-mode** (by banacorn), and install it.
3. Open Settings (`Ctrl+,`), search for `agda path`, and set it to the absolute path of your Agda binary:

   ```
   /home/<your-username>/.cabal/bin/agda
   ```

4. Open any `.agda` file and press `Ctrl+C Ctrl+L` to load it. Syntax highlighting and goal display should activate.

### 5b. WSL (Windows Subsystem for Linux)

Because Agda runs inside WSL, VS Code must bridge to the Linux environment:

1. Install the **WSL** extension (by Microsoft) in VS Code.
2. Click the green `><` button in the bottom-left corner and select **Reopen Folder in WSL**. The status bar should show `WSL: Ubuntu` (or your distro name).
3. In the WSL-connected window, install the **agda-mode** extension. Make sure you click **Install in WSL: Ubuntu** (not the local Windows side).
4. Open Settings (`Ctrl+,`), switch to the **Remote [WSL]** tab, search for `agda path`, and set it to:

   ```
   /home/<your-username>/.cabal/bin/agda
   ```

5. Open any `.agda` file and press `Ctrl+C Ctrl+L`. If you see `*All Done*` at the bottom, the bridge is working.

## 6. Python Oracle Environment

The `sim/prototyping/` scripts (01–17) require Python 3.12 with NetworkX and NumPy. Two options:

### Option A: Nix (Reproducible, Recommended)

If you have Nix installed ([NixOS](https://nixos.org/) or the standalone installer):

```bash
cd sim/prototyping
nix-shell     # enters the pinned environment
```

The `shell.nix` in that directory pins NixOS 24.05, Python 3.12, NetworkX 3.6.1, and NumPy 2.4.4.

### Option B: Python venv (Manual)

```bash
cd sim/prototyping
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

The `requirements.txt` pins:

```
networkx==3.6.1
numpy==2.4.4
```

Verify:

```bash
python3 -c "import networkx; print(networkx.__version__)"  # 3.6.1
python3 -c "import numpy; print(numpy.__version__)"        # 2.4.4
```

## 7. Environment Verification

Create a scratch file to confirm the full stack works:

```bash
mkdir -p /tmp/agda-test && cd /tmp/agda-test
cat > PhaseZero.agda << 'EOF'
{-# OPTIONS --cubical --safe #-}
module PhaseZero where

open import Cubical.Foundations.Prelude

identity-path : ∀ {ℓ} {A : Type ℓ} (a : A) → a ≡ a
identity-path a = refl
EOF

agda PhaseZero.agda
```

If the command completes without errors, **your Agda + cubical environment is ready**.

To verify the Python side:

```bash
cd <repo-root>/sim/prototyping
python3 01_happy_patch_cuts.py   # should print the full verification output
```

## 8. Cloning the Repository

```bash
git clone https://github.com/m4ximum-opus/univalence-gravity.git
cd univalence-gravity
```

If you encounter permission errors when saving files (common on WSL), reclaim ownership:

```bash
sudo chown -R $(whoami):$(whoami) ~/univalence-gravity
```

## 9. Recorded Stable Versions

All proofs in this repository are checked against the following toolchain:

| Component   | Version       | Notes                                |
|-------------|---------------|--------------------------------------|
| GHC         | 9.6.7         | via GHCup                            |
| Cabal       | 3.14.2.0      | via GHCup                            |
| Agda        | 2.8.0         | `cabal install Agda-2.8.0`           |
| cubical     | April 2026    | `git clone` of `agda/cubical` HEAD   |
| Python      | 3.12          | for `sim/prototyping/` oracle scripts|
| NetworkX    | 3.6.1         | graph algorithms (max-flow/min-cut)  |
| NumPy       | 2.4.4         | Coxeter geometry (matrix operations) |
| NixOS (opt.)| 24.05         | pinned in `sim/prototyping/shell.nix`|

## Next Steps

- **[Building](building.md)** — how to type-check specific modules and the recommended load order.
- **[Architecture](architecture.md)** — module dependency DAG and layer diagram.
- **[Abstract](abstract.md)** — one-page summary of all machine-checked results.