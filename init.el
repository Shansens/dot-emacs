;;; init.el --- main Emacs initialization
;;; Commentary:
;;; Setup Emacs, make it homely and cosy
;; Author: Christian Kellner <christian@kellner.me>

;;; Code:

; -=[ sane defaults
(setq gc-cons-threshold (* 128 1024 1024))
(blink-cursor-mode 0)
(setq inhibit-splash-screen t)
(setq inhibit-startup-message t)
(setq make-backup-files nil)
(fset 'yes-or-no-p 'y-or-n-p)
(set-scroll-bar-mode (quote right))
(tooltip-mode -1)
(tool-bar-mode -1)
(line-number-mode 1)
(column-number-mode 1)
(show-paren-mode 1)
(delete-selection-mode t)
(global-auto-revert-mode t)
(global-linum-mode t)
(setq-default linum-format "%4d ")
(setq use-dialog-box nil)
(prefer-coding-system 'utf-8)

;; Disable Ctrl-Z minimization/suspension of emacs.
(global-set-key [C-z] nil)

;; visual bell causes rendering errors
;; use custom function from 'stack-exchange'
(setq ring-bell-function
      (lambda ()
	(unless (memq this-command
		      '(isearch-abort abort-recursive-edit
				      exit-minibuffer keyboard-quit))
	  (invert-face 'mode-line)
	  (run-with-timer 0.1 nil 'invert-face 'mode-line))))

;; Title bar shows name of current buffer.
(setq frame-title-format '("emacs: %*%+ %b"))

;; -=[ custom - write custom's settings to separate file
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)

;; === package management
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "http://melpa.org/packages/") t)
(add-to-list 'package-archives
	     '("marmalade" . "http://marmalade-repo.org/packages/") t)

;; no auto package loading,
;; loading is handled via use-package
(setq package-enable-at-startup nil)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package)
  (use-package cl))

(require 'diminish)
(require 'bind-key)

(setq use-package-always-ensure t)

;; -=[ OSX
(when (eq system-type 'darwin)
  (let ((default-directory "/usr/local/share/emacs/site-lisp/"))
    (normal-top-level-add-subdirs-to-load-path))
  (setq mac-option-modifier 'meta)
  (if (boundp 'mac-auto-operator-composition-mode)
      (mac-auto-operator-composition-mode))
  (setq-default locate-command "mdfind")
  (when (display-graphic-p)
    (setq-default mac-emulate-three-button-mouse t)
    (global-set-key (kbd "M-`") 'other-frame))
  )

;; pick up the correct path from a login shell
(use-package exec-path-from-shell
  :if (eq system-type 'darwin)
  :init
  (customize-set-variable 'exec-path-from-shell-arguments nil)
  :config
  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-env "GOPATH"))

(use-package reveal-in-osx-finder
  :commands (reveal-in-osx-finder))

;; -=[ Editing

;; multiple cursors
(use-package multiple-cursors
  :bind (("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this)))

; -=[ EditorConfig

(use-package editorconfig
    :init
    (editorconfig-mode 1))

; -=[ interactively do things

(use-package ido
  :init
  (ido-mode t)
  :config
  ;; prevent ido to globally search for files automatically
  (setq ido-auto-merge-work-directories-length -1)
  (define-key ido-file-dir-completion-map (kbd "C-c C-s")
    (lambda()
      (interactive)
      (ido-initiate-auto-merge (current-buffer))))
  (use-package flx-ido
    :init
    (flx-ido-mode t)))

; -=[ Projects via projectile
(use-package projectile
  :config
  (projectile-global-mode t)
  (setq projectile-mode-line '(:eval (format " Ⓟ〔%s〕" (projectile-project-name)))))

; -=[ flycheck
(use-package flycheck
  :commands global-flycheck-mode
  :diminish " ⓕ"
  :init
  (add-hook 'after-init-hook #'global-flycheck-mode)
  :config
  (use-package flycheck-pos-tip))

;; -=[ git
(use-package git-gutter-fringe
  :diminish (git-gutter-mode . "")
  :config
  (setq git-gutter-fr:side 'right-fringe)
  ;;(setq-default right-fringe-width 22)
  (add-hook 'prog-mode-hook #'git-gutter-mode))

(use-package gitconfig-mode
  :mode (("\\.gitconfig\\'" . gitconfig-mode)
	 ("\\.git/config\\'" . gitconfig-mode)
	 ("\\.gitmodules\\'" . gitconfig-mode)))

(use-package gitignore-mode
  :mode ("\\.gitignore\\'" . gitignore-mode))

(use-package git-timemachine
  :commands git-timemachine
  :config
  (setq git-timemachine-abbreviation-length 6))

(use-package magit
  :bind (("C-x g" . magit-status))
  :config
  (setq magit-diff-refine-hunk t))

;; -=[ yasnippet
(use-package yasnippet
  :diminish (yas-minor-mode . " ⓨ")
  :config
  (add-hook 'prog-mode-hook #'yas-minor-mode))

; === autocompletion
(use-package company
  :diminish " ⓒ"
  :init
  (add-hook 'after-init-hook 'global-company-mode)
  :config
  (setq company-tooltip-align-annotations t))

(use-package restclient
  :mode ("\\.http\\'" . restclient-mode))

;; == backup ==
(defun make-backup-file-name (filename)
  (defvar backups-dir "~/.backups/")
  (make-directory backups-dir t)
  (expand-file-name
   (concat backups-dir "."  (file-name-nondirectory filename) "~")
   (file-name-directory filename)))

; == recent files ==
(recentf-mode 1)
(global-set-key (kbd "C-c r") 'recentf-open-files)

; == uniquify ==
(require 'uniquify)
(setq uniquify-after-kill-buffer-p t)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)

;; -=[ text formats
(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :init (setq markdown-command "multimarkdown"))

;; -=[ pdf viewing
(use-package doc-view
  :defer t
  :config
  (setq doc-view-continuous t)
  (add-hook 'doc-view-mode-hook
            (lambda ()
              (linum-mode -1)
              )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Programming mode customizations
(setq-default show-trailing-whitespace t)

; -=[ common packages
(use-package rainbow-delimiters
  :commands rainbow-delimiters-mode)

(use-package paredit
  :commands enable-paredit-mode)


; -=[ C/C++/ObjC and friends
(setq c-hungry-delete-key t)

(add-hook 'c-mode-common-hook
	  (lambda ()
	    (setq indent-tabs-mode nil)
	    (setq c-indent-level 4)
	    (font-lock-add-keywords nil
				    '(("\\<\\(FIXME\\):" 1 font-lock-warning-face t)))
	    (define-key c-mode-base-map (kbd "C-c o") 'ff-find-other-file)
	    ))

; objc mode for header files
(add-to-list 'magic-mode-alist
	     `(,(lambda ()
		  (and (string= (file-name-extension (or buffer-file-name "DEF-NAME")) "h")
		       (re-search-forward "@\\<interface\\>"
					  magic-mode-regexp-match-limit t)))
	       . objc-mode))

(defconst cc-style-nix
  '("cc-mode"
    (c-offsets-alist . ((innamespace . [0])))))
(c-add-style "cc-style-nix" cc-style-nix)

(use-package irony
  :commands irony-mode
  :diminish " ⓘ"
  :init
  (add-hook 'c-mode-common-hook 'irony-mode)
  :config
  (custom-set-variables '(irony-additional-clang-options '("-std=c++11")))
  (add-to-list 'company-backends 'company-irony)
  (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
  (use-package company-irony
    :config
    (company-irony-setup-begin-commands))
  (use-package flycheck-irony
    :after flycheck
    :config
    (flycheck-irony-setup))
  (use-package irony-eldoc
     :init
     (add-hook 'irony-mode-hook 'irony-eldoc)))

(use-package rtags
  :bind (:map c-mode-base-map
	      ("M-." . rtags-find-symbol-at-point)))

(use-package cmake-ide
  :commands cmake-ide-setup
  :init
  (add-hook 'c-mode-common-hook 'cmake-ide-setup)
  :config
  (message "cmake ide starting")
  (require 'rtags))

(use-package cmake-mode
  :mode (("CMakeLists\\.txt\\'" . cmake-mode)
	 ("\\.cmake\\'" . cmake-mode)))

(use-package cuda-mode
  :mode "\\.cu\\'")

;; -=[ docker
(use-package dockerfile-mode
  :mode "Dockerfile\\'")

(use-package docker
  :defer t)

; -=[ clojure
(use-package clojure-mode
  :mode "\\.clj"
  :config
  (add-hook 'clojure-mode-hook 'enable-paredit-mode)
  (add-hook 'clojure-mode-hook 'subword-mode)
  (add-hook 'clojure-mode-hook 'rainbow-delimiters-mode)
  (use-package clojure-mode-extra-font-locking))

; -=[ Fortran
(use-package f90
  :mode ("\\.[fF]\\(03\\|08\\)\\'" . f90-mode))

; -=[ Go
(use-package go-mode
  :mode "\\.go\\'"
  :bind (:map go-mode-map
	      ("M-." . godef-jump)
	      ("M-," . godef-jump-back)
	      ("C-c C-r" . go-rename))
  :config
  (add-hook 'before-save-hook 'gofmt-before-save)
  (setq gofmt-command "goreturns")
  (use-package go-guru)
  (use-package go-stacktracer)
  (use-package go-playground)
  (use-package go-dlv)
  (use-package company-go
    :config
    (add-to-list 'company-backends 'company-go))
  )

(use-package go-rename
  :commands (go-rename))

(use-package go-eldoc
  :commands (go-eldoc-setup)
  :init
  (add-hook 'go-mode-hook 'go-eldoc-setup))

;; -=[ Python
(use-package elpy
  :commands elpy-enable
  :init
  (with-eval-after-load 'python
    (elpy-enable))
  :config
  (setq-default flycheck-flake8-maximum-line-length 100)
  (setq elpy-rpc-backend "jedi")
  (setq elpy-modules (delq 'elpy-module-flymake elpy-modules)))

(use-package ein
  :defer t)

;; -=[ Rust
(use-package rust-mode
  :mode "\\.rs\\'"
  :config
  (add-hook 'rust-mode-hock 'rustfmt-enable-on-save)
  (use-package flycheck-rust
    :after flycheck
    :config
    (flycheck-rust-setup)))

(use-package racer
  :commands racer-mode
  :init
  (add-hook 'rust-mode-hook 'racer-mode)
  :bind (:map rust-mode-map
	 ("M-." . racer-find-definition)
	 ("TAB" . racer-complete-or-indent))
  :config
  (racer-turn-on-eldoc)
  (use-package company-racer
    :config
    (add-to-list 'company-backends 'company-racer)))


;; -=[ documentation
(use-package dash-at-point
  :bind (("C-c d" . dash-at-point)))

(use-package eldoc
  :commands eldoc-mode
  :diminish eldoc-mode)

;; === I will never learn how to spell ===
(defun ck-find-langtool ()
  "Find the locations of all available langtool jar (sorted) or nil."
  (let ((basedir '"/usr/local/Cellar/languagetool")
	(suffix '"/libexec/languagetool-commandline.jar"))
    (if (file-exists-p basedir)
	(mapcar (lambda (d) (concat d suffix))
		(reverse (sort
			  (directory-files basedir t "[0-9].*" t)
			  'string<))))))

(use-package langtool
  :bind (("C-x c w" . langtool-check)
         ("C-x c W" . langtool-check-done)
         ("C-x c l" . langtool-switch-default-language)
         ("C-x c 4" . langtool-show-message-at-point)
         ("C-x c c" . langtool-correct-buffer))
  :config
  (setq langtool-language-tool-jar (car (ck-find-langtool))
	langtool-default-language "en-US"
	langtool-disabled-rules '("WHITESPACE_RULE"
				  "EN_UNPAIRED_BRACKETS"
				  "COMMA_PARENTHESIS_WHITESPACE"
				  "EN_QUOTES")))
(use-package synosaurus
  :bind ("C-c s l" . synosaurus-lookup)
  :config (setq synosaurus-backend 'synosaurus-backend-wordnet))

(use-package flyspell
  :commands (flyspell-prog-mode flyspell-mode flyspell-buffer)
  :diminish (flyspell-mode flyspell-prog-mode)
  :init
  (add-hook 'prog-mode-hook #'flyspell-prog-mode)
  :config
  (setq flyspell-issue-message-flag nil))

;; -=[ UI
;; resize the initial emacs window
;;(add-to-list 'default-frame-alist '(height . 40))
;;(add-to-list 'default-frame-alist '(width . 150))

(use-package neotree
  :bind (("<f8>" . neotree-toggle))
  :config
  (setq neo-vc-integration nil
	neo-banner-message nil
	neo-show-updir-line nil
	projectile-switch-project-action 'neotree-projectile-action)

  ;; shamelessly 'borrowed' from doom color theme
  (defun ck*neo-insert-root-entry (node)
    "Pretty-print pwd in neotree"
    (list (concat "  " (projectile-project-name))))
  (defun ck*neo-insert-fold-symbol (name)
    "Custom hybrid unicode theme with leading whitespace."
    (or (and (eq name 'open)  (neo-buffer--insert-with-face " -  " 'neo-expand-btn-face))
	(and (eq name 'close) (neo-buffer--insert-with-face " +  " 'neo-expand-btn-face))
	(and (eq name 'leaf)  (neo-buffer--insert-with-face "   " 'neo-expand-btn-face))))
  (advice-add 'neo-buffer--insert-fold-symbol :override 'ck*neo-insert-fold-symbol)
  (advice-add 'neo-buffer--insert-root-entry :filter-args 'ck*neo-insert-root-entry))

;; -=[ fonts
(defconst ck-fonts
      '(("Hasklig" 12)
	("Source Code Pro" 12)
	("Inconsolata" 12)
	("Menlo" 12)))

(defun font-existsp (name size)
  "Check if a font with a given NAME (or is Powerline version) and SIZE exists."
  (cond ((find-font (font-spec :name (concat name " for Powerline")))
	 (format "%s for Powerline-%d" name size))
	((find-font (font-spec :name name))
	 (format "%s-%d" name size))))

(defun ck-first-font (lst)
  "Return the first valid font from LST."
  (or (apply 'font-existsp (car lst))
      (ck-first-font (cdr lst))))

(when (display-graphic-p)
 (let ((foo-font (ck-first-font ck-fonts)))
  (set-face-attribute 'default nil :font foo-font)
  (message (concat "Setting font to: " foo-font))
  ))

(use-package powerline
  :config
  (powerline-default-theme))

;; -=[ color themes

;;(use-package leuven-theme)

(let ((default-directory "~/.emacs.d/themes/"))
  (normal-top-level-add-subdirs-to-load-path))
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/doom/")
(load-theme 'doom-one t)



;; all done, pheww
;;; init.el ends here
