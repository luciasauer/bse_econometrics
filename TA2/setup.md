# 📦 Setup Guide for TA 2

As in every session, you will need to pull the latest materials from the GitHub repository.

```bash
git pull origin main
```

In this session, we will work with **R** and **R Markdown** files (`.Rmd`).

You will need to install **R**, **Pandoc**, and an editor that supports R Markdown.

You can work in either **RStudio** or **Visual Studio Code (VS Code)**, I will do it in VS Code because I like to have everything in one place, but RStudio is also a great option 😊.



---

## 1️⃣ Install R

R is the main language we will use.

* Download R from [CRAN](https://cran.r-project.org/).
* Choose the installer for your operating system (Windows, macOS, Linux).
* Follow the default installation steps.

👉 To check your installation, run in the terminal:

```bash
R --version
```

---

## 2️⃣ Install Pandoc

Pandoc is required for rendering R Markdown (`.Rmd`) to HTML/PDF/Word.

* **Windows**: Download from [Pandoc releases](https://pandoc.org/installing.html) and install.
* **macOS**: 
    ```bash
      brew install pandoc
    ```
* **Linux**: You can usually install via your package manager, e.g.:

  ```bash
  sudo apt-get install pandoc
  ```

👉 Check installation with:

```bash
pandoc --version
```

---

## 3️⃣ Choose an Editor

### Option A: **Visual Studio Code (VS Code)**

If you prefer to code in VS Code, install:

1. Inside VS Code, install the following extensions:

   * **R Extension** (by Yuki Ueda) → adds R language support.
   * **R Tools** (or R Debugger) → for running R interactively.
   * **Markdown All in One** → better Markdown editing.


### Option B: **RStudio**

* Download from [RStudio download page](https://posit.co/download/rstudio-desktop/).
* Recommended for beginners: it comes with Pandoc and is tightly integrated with R Markdown.

---


✅ That’s it! After these steps, you’ll be ready to open the `.Rmd` notebook for **TA Session 2** and follow along.
