# Cubical Agda Development Setup (WSL / Ubuntu)

### 1. System Dependencies
Install core build tools and C-libraries required by the compiler:
```bash
sudo apt update 
sudo apt install curl build-essential zlib1g-dev -y
```

### 2. Haskell Toolchain (GHCup)
Install the Glasgow Haskell Compiler (GHC) and Cabal (the package manager).
```bash
curl --proto '=https' --tlsv1.2 -sSf [https://get-ghcup.haskell.org](https://get-ghcup.haskell.org) | sh
```
*Note: Accept the defaults. When it finishes, restart your terminal or run `source ~/.bashrc` so the `cabal` command becomes available!*

### 3. Agda Compiler
Install Agda via Cabal. *(Takes ~15-30 minutes)*
```bash
sudo apt install cabal-install
cabal update
cabal install Agda
```
*Note: This installs the Agda executable to `/home/<your_username>/.cabal/bin/agda`.*

### 4. Library Setup (Cubical)
Clone the `agda/cubical` library and link it to your local Agda environment.
```bash
mkdir -p ~/agda-libs
cd ~/agda-libs
git clone [https://github.com/agda/cubical.git](https://github.com/agda/cubical.git)

mkdir -p ~/.agda
```
**CRITICAL:** Agda is highly literal and does NOT understand bash variables like `$HOME` in its config files. You must use `~/` or an absolute path.
```bash
echo "~/agda-libs/cubical/cubical.agda-lib" > ~/.agda/libraries
echo "cubical" > ~/.agda/defaults
```

### 5. Editor Setup (The WSL Bridge)
Because Agda is installed in Linux, VS Code needs to be explicitly configured to speak to WSL.
1. Open VS Code: `code .`
2. Install the **WSL** extension (by Microsoft).
3. Click the blue `><` button in the bottom left corner and select **Reopen Folder in WSL**. Ensure the bottom left corner says `WSL: Ubuntu`.
4. Go to the Extensions tab and install **agda-mode** (by banacorn). *Ensure you click "Install in WSL: Ubuntu".*
5. Open Settings (`Ctrl + ,`) and click the **Remote [WSL]** tab.
6. Search for `agda path` -> click **Add Item** -> enter your absolute path: `/home/<your_username>/.cabal/bin/agda`.

### 6. Phase Zero: Environment Check
Before starting your main project, verify the compiler, library, and extension are communicating perfectly.

1. Create a test directory and file:
```bash
mkdir -p ~/agda-test/src
cd ~/agda-test
code .
```
2. Create `src/PhaseZero.agda` and paste the following:
```agda
{-# OPTIONS --cubical --guardedness #-}
module PhaseZero where

open import Cubical.Foundations.Prelude

-- A trivial proof to check your environment
identity-path : ∀ {ℓ} {A : Type ℓ} (a : A) → a ≡ a
identity-path a = refl
```
3. In VS Code, open the Command Palette (`Ctrl + Shift + P`) and run **`Agda: Restart`**.
4. Load the file using the Agda shortcut: **`Ctrl + C` followed by `Ctrl + L`**.
*If the syntax highlights lock in and you see `*All Done*` at the bottom, your environment is ready!*

### 7. Create Main Repository
```bash
cd ~
mkdir univalence-gravity
cd univalence-gravity
code .
```
*(If you run into permission errors when saving files, reclaim folder ownership with: `sudo chown -R <your_username>:<your_username> ~/univalence-gravity`)*

---

**Recorded Stable Versions (April 2026):**
- GHC: `9.6.7`
- Cabal: `3.14.2.0` (via GHCup)
- Agda: `2.8.0`