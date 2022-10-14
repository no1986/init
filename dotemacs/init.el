;;; package --- Summary
;;; Commentary:
;;; Code:

;; プロキシ環境の場合はここでプロキシの設定を実施
;;(setq url-proxy-services
;;      '(("http" . "127.0.0.1:10000")
;;        ("https" . "127.0.0.1:10000")))

(eval-and-compile
  (customize-set-variable
   'package-archives '(("org" . "https://orgmode.org/elpa/")
                       ("melpa" . "https://melpa.org/packages/")
                       ("gnu" . "https://elpa.gnu.org/packages/")))
  (package-initialize)
  (unless (package-installed-p 'leaf)
    (package-refresh-contents)
    (package-install 'leaf))

  (leaf macrostep
    :ensure t
    :bind (("C-c e" . macrostep-expand)))

  (leaf leaf-keywords
    :ensure t
    :init
    (leaf hydra :ensure t)
    (leaf el-get :ensure t)
    (leaf blackout :ensure t)
    (leaf diminish :ensure t)
    :config
    (leaf-keywords-init)))

(leaf *common
  :disabled
  :config
  (leaf *builtins
    :doc "define customization properties of builtins"
    :config
    (fset 'yes-or-no-p 'y-or-n-p)

    (leaf cus-edit
      :custom
      `((custom-file . ,(locate-user-emacs-file "custom.el")))
      :hook
      `((kill-emacs-hook
         . (lambda ()
             (if (file-exists-p custom-file)
                 (delete-file custom-file))))))

    (leaf cus-start
      :custom
      (
       ;; 折り返し表示
       (truncate-lines . nil)
       ;; 不要なもの表示OFF
       (menu-bar-mode . nil)
       (tool-bar-mode . nil)
       (scroll-bar-mode . nil)
       (indent-tabs-mode . nil)
       ;; バックアップファイルの自動生成OFF
       (make-backup-files . nil)
       (auto-save-default . nil)
       (auto-save-list-file-prefix . nil)
       ;; 行番号、列番号表示
       (column-number-mode . t)
       (line-number-mode . t)
       (global-display-line-numbers-mode . t)
       ;; ファイルサイズを表示
       (size-indication-mode . nil)
       ;; 対応する括弧を自動入力
       (electric-pair-mode . t)
       ;; kill ring
       (kill-ring-max . 1000)
       (kill-read-only-ok . t)
       (kill-whole-line . t)
       )
      :config
      ;; ARevをdiminish
      (diminish 'auto-revert-mode)
      ;; ELDocをdiminish
      (diminish 'eldoc-mode)
      )

    (leaf dired
      :bind
      (dired-mode-map
       ;; テキストのように編集
       ("e" . wdired-change-to-wdired-mode)
       ;; 上のディレクトリに移動移動
       ("r" . dired-up-directory)
       ;; シンボリックリンクを作成
       ("l" . dired-do-symlink)
       )
      :config
      ;; diredの表示形式変更
      (setq dired-listing-switches (purecopy "-Ahvl --time-style long-iso"))
      ;; 2ウィンドウ時にファイルコピーや移動をした場合に現在表示している片方のディレクトリをデフォルト移動先にする
      (setq dired-dwim-target t)
      ;; diredバッファでC-sした時にファイル名のみマッチ
      (setq dired-isearch-filenames t)

      (leaf dired-quick-sort
        :doc "ソート機能を拡張"
        :ensure t
        :config
        (dired-quick-sort-setup))
      )

    (leaf cua
      :config
      (cua-mode t)
      (setq cua-enable-cua-keys nil)
      (bind-key* "M-SPC" 'cua-set-rectangle-mark)
      )

    (leaf *ediff
      :config
      ;; コントロール用のバッファを同一フレーム内に表示
      (setq ediff-window-setup-function 'ediff-setup-windows-plain)
      ;; diffのバッファを上下ではなく左右に並べる
      (setq ediff-split-window-function 'split-window-horizontally)
      (custom-set-faces
       '(ediff-current-diff-A ((t (:background "#ffdddd"))))
       '(ediff-current-diff-B ((t (:background "#ddffdd"))))
       '(ediff-current-diff-C ((t (:background "#ffffaa"))))
       '(ediff-even-diff-A    ((t (:background "light grey"))))
       '(ediff-even-diff-B    ((t (:background "Grey"))))
       '(ediff-even-diff-C    ((t (:background "light grey"))))
       '(ediff-fine-diff-A    ((t (:background "#ffbbbb"))))
       '(ediff-fine-diff-B    ((t (:background "#aaffaa"))))
       '(ediff-fine-diff-C    ((t (:background "#ffff55"))))
       )
      )
    )

  (leaf bind-key
    :ensure t
    :bind
    ("C-x l" . toggle-truncate-lines)
    ("C-c n" . global-display-line-numbers-mode)
    ("M-t" . nil)
    ("C-j" . nil)
    ("M-j" . nil)
    ("C-x C-d" . dired)
    :config
    ;; C-hをバックスペースにする
    (define-key key-translation-map [?\C-h] [?\C-?])

    (leaf yafolding
      :doc "コードの折り畳み"
      :ensure t
      :hook find-file-hook
      :bind
      (yafolding-mode-map
       ("C-j j" . yafolding-toggle-element)
       ("C-j s" . yafolding-show-all)
       ("C-j h" . yafolding-hide-all)
       )
      )

    (leaf *window
      :config
      (defun window-toggle-division ()
        "ウィンドウ 2 分割時に、縦分割<->横分割"
        (interactive)
        (unless (= (count-windows 1) 2)
          (error "ウィンドウが 2 分割されていません。"))
        (let ((before-height)
              (other-buf (window-buffer (next-window))))
          (setq before-height (window-height))
          (delete-other-windows)
          (if (= (window-height) before-height)
              (split-window-vertically)
            (split-window-horizontally))
          (other-window 1)
          (switch-to-buffer other-buf)
          (other-window -1)))
      (bind-key "C-c t" 'window-toggle-division)

      (leaf ace-window
        :ensure t
        :config
        (defun my-ace-window ()
          "画面が1つの時は画面を分割して移動、
       画面が3個以下の時は1画面ずつ移動、
       4画面以上の場合は指定して移動"
          (interactive)
          (cond ((= (count-windows) 1)
                 (split-window-right)
                 (other-window 1))
                ((> (count-windows) 4)
                 (ace-window 0))
                (t (other-window 1))))
        (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
        (bind-key* "C-t" 'my-ace-window)
        )
      )

    (leaf mwim
      :ensure t
      :bind
      ("C-a" . mwim-beginning-of-line-or-code)
      ("C-e" . mwim-end-of-code-or-line)
      )

    (leaf elscreen
      :ensure t
      :config
      (setq elscreen-tab-display-control nil)
      (setq elscreen-tab-display-kill-screen nil)
      (setq elscreen-prefix-key (kbd "C-q"))
      (bind-key* "M-n" 'elscreen-next)
      (bind-key* "M-p" 'elscreen-previous)
      (bind-key* "C-z" 'suspend-emacs)

      (elscreen-start)
      (custom-set-faces
       '(elscreen-tab-current-screen-face
         ((t (:background "#a8a8a8" :foreground "#000000"))))
       '(elscreen-tab-other-screen-face
         ((t (:background "#292929" :foreground "#a5a5a5"))))
       '(elscreen-tab-background-face
         ((t (:background "#585858"))))
       )
      )
    )

  (leaf *undo
    :config
    (leaf undo-tree
      :ensure t
      :diminish (undo-tree-mode "")
      :bind ("C-x u" . undo-tree-visualize)
      :custom
      (global-undo-tree-mode . t)
      (undo-tree-auto-save-history . nil)
      )
    )

  (leaf *tips
    :config
    (leaf which-key
      :doc "emacsのショートカットで次のキーを表示"
      :ensure t
      :diminish t
      :config
      (which-key-mode))

    (leaf midnight
      :doc "バッファを自動でkillする"
      :ensure t
      :config
      (setq clean-buffer-list-delay-general t))

    (leaf projectile
      :ensure t
      :config
      (projectile-mode t))

    (leaf sudo-edit
      :ensure t)
    )

  (leaf flycheck
    :ensure t
    :init
    (global-flycheck-mode t)
    :bind
    ("M-t f" . flycheck-next-error)
    ("M-t l" . list-flycheck-errors)
    )
  )

(leaf vertico
  :disabled
  :ensure t
  :config
  (vertico-mode)
  (setq vertico-count 20)

  (leaf savehist
    :init
    (savehist-mode))

  (leaf consult
    :ensure t
    :init
    (defun consult-line-symbol-at-point ()
      (interactive)
      (consult-line (thing-at-point 'symbol)))
    (defun consult-line-multi-symbol-at-point ()
      (interactive)
      (consult-line-multi (thing-at-point 'symbol)))
    (defun consult-ripgrep-symbol-at-point ()
      (interactive)
      (consult-ripgrep nil (thing-at-point 'symbol)))
    :bind
    ("C-x C-b" . project-find-file)
    ("C-x b" . consult-buffer)
    ("C-x f" . consult-recent-file)
    ("M-o" . consult-line-multi-symbol-at-point)
    ("C-o" . consult-line-symbol-at-point)
    ("C-c i" . consult-imenu)
    ("C-c r g" . consult-grep)
    ("C-c r r" . consult-ripgrep-symbol-at-point)
    ("M-g g" . consult-goto-line)
    ("M-y" . consult-yank-from-kill-ring)
    :config
    (recentf-mode)
    (autoload 'projectile-project-root "projectile")
    (setq consult-project-function (lambda (_) (projectile-project-root)))
    (setq consult-buffer-sources
          '(consult--source-hidden-buffer
            consult--source-modified-buffer
            consult--source-buffer
            consult--source-recent-file
            consult--source-bookmark
            consult--source-project-buffer
            consult--source-project-recent-file)
          )
    )

  (leaf consult-ghq
    :ensure t
    :bind
    ("C-x c g" . consult-ghq-grep)
    ("C-x c f" . consult-ghq-find)
    )

  (leaf orderless
    :disabled
    :ensure t
    :init
    (leaf migemo
      :ensure t
      :diminish
      :config
      (setq migemo-command "cmigemo")
      (setq migemo-options '("-q" "-e"))
      (setq migemo-dictionary "/usr/share/cmigemo/utf-8/migemo-dict")
      (setq migemo-user-dictionary nil)
      (setq migemo-regex-dictionary nil)
      (setq migemo-coding-system 'utf-8-unix)
      (load-library "migemo")
      (migemo-init)
      )
    :config
    (setq completion-styles '(orderless))
    (leaf *my-orderless-migemo-setting
      :after orderless
      :config
      (icomplete-mode)
      (defun orderless-migemo (component)
        (let ((pattern (migemo-get-pattern component)))
          (condition-case nil
              (progn (string-match-p pattern "") pattern)
            (invalid-regexp nil))))
      (orderless-define-completion-style orderless-default-style
        (orderless-matching-styles '(orderless-literal
                                     orderless-regexp)))
      (orderless-define-completion-style orderless-migemo-style
        (orderless-matching-styles '(orderless-literal
                                     orderless-regexp
                                     orderless-migemo)))
      (setq completion-category-overrides
            '((command (styles orderless-default-style))
              (file (styles orderless-migemo-style))
              (buffer (styles orderless-migemo-style))
              (symbol (styles orderless-default-style))
              ;; category consult-location は consult-line などに使われる
              (consult-location (styles orderless-migemo-style))
              ;; category consult-multi は consult-buffer などに使われる
              (consult-multi (styles orderless-migemo-style))
              (unicode-name (styles orderless-migemo-style))
              (variable (styles orderless-default-style))))
      )
    )

  (leaf marginalia
    :ensure t
    :init
    (marginalia-mode)
    :config
    (add-to-list 'marginalia-prompt-categories
                 '("\\<File\\>" . file))
    )

  (leaf embark
    :ensure t
    :bind
    ("C-c m" . embark-act))

  (leaf embark-consult
    :ensure t
    :after (embark consult)
    :hook
    (embark-collect-mode . consult-preview-at-point-mode))
  )

(leaf *color
  :disabled
  :config
  (leaf doom-themes
    :ensure t
    :config
    (load-theme 'doom-molokai t)
    (leaf all-the-icons
      :ensure t
      :config
      (all-the-icons-install-fonts t))
    (leaf doom-modeline
      :ensure t
      :custom
      (mode-line          . '((t (:background "#5f5f5f"))))
      (mode-line-inactive . '((t (:background "#101010" :foreground "#454545"))))
      :config
      (setq doom-modeline-buffer-file-name-style 'truncate-with-project)
      (setq doom-modeline-icon t)
      (setq doom-modeline-major-mode-icon t)
      (setq doom-modeline-major-mode-color-icon t)
      (setq doom-modeline-buffer-state-icon t)
      (setq doom-modeline-buffer-modification-icon t)
      (setq doom-modeline-unicode-fallback t)
      (setq doom-modeline-height 25)
      (setq doom-modeline-bar-width 3)
      (setq doom-modeline-icon (display-graphic-p))
      (setq doom-modeline-buffer-encoding nil)
      (setq doom-modeline-minor-modes t)
      (setq doom-modeline-lsp nil)
      (doom-modeline-mode))
    )

  (leaf *face
    :config
    ;; test
    (custom-set-faces
     '(default                   ((t (:background "#030303"))))
     '(font-lock-comment-face    ((t (:foreground "#eeee00"))))
     '(hl-line                   ((t (:background "#204040" :weight bold))))
     '(dired-ignored             ((t (:foreground "#afafaf"))))
     '(region                    ((t (:background "#502020"))))
     '(cua-rectangle             ((t (:background "#502020"))))
     '(show-paren-match          ((t (:background "#a000a0"))))
     '(line-number               ((t (:background "#141414" :foreground "#707070"))))
     '(line-number-current-line  ((t (:foreground "#ffffff"))))
     '(vertical-border           ((t (:background "#8b8386" :foreground "#8b8386"))))
     '(ediff-current-diff-A      ((t (:background "#205050" :foreground "#ffffff"))))
     '(ediff-current-diff-B      ((t (:background "#205050" :foreground "#ffffff"))))
     '(ediff-even-diff-A         ((t (:background "#000000" :foreground "#b6e63e"))))
     '(ediff-even-diff-B         ((t (:background "#000000" :foreground "#b6e63e"))))
     '(ediff-fine-diff-A         ((t (:foreground "#b6e63e" :foreground "ffffff"))))
     '(ediff-fine-diff-B         ((t (:foreground "#b6e63e" :foreground "ffffff")))))
    (global-hl-line-mode t)
    (defun my-face-at-point ()
      (let ((face (get-text-property (point) 'face)))
        (or (and (face-list-p face)
                 (car face))
            (and (symbolp face)
                 face))))

    (defun my-describe-face (&rest ignore)
      (interactive (list (read-face-name "Describe face"
                                         (or (my-face-at-point) 'default)
                                         t)))
      nil)

    (eval-after-load "hl-line"
      '(advice-add 'describe-face :before #'my-describe-face))
    (setq show-parent-delay 0)
    (show-paren-mode t)
    )

  (leaf rainbow-delimiters
    :ensure t
    :config
    (rainbow-delimiters-mode t)
    (add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

    (require 'cl-lib)
    (require 'color)
    (custom-set-faces
     '(rainbow-delimiters-depth-1-face ((t (:foreground "#cd0000"))))
     '(rainbow-delimiters-depth-2-face ((t (:foreground "#00cd00"))))
     '(rainbow-delimiters-depth-3-face ((t (:foreground "#cdcd00"))))
     '(rainbow-delimiters-depth-4-face ((t (:foreground "#00cdff"))))
     '(rainbow-delimiters-depth-5-face ((t (:foreground "#cdcdff"))))
     '(rainbow-delimiters-depth-6-face ((t (:foreground "#ff0000"))))
     '(rainbow-delimiters-depth-7-face ((t (:foreground "#00ff00"))))
     '(rainbow-delimiters-depth-8-face ((t (:foreground "#ffff00"))))
     '(rainbow-delimiters-depth-9-face ((t (:foreground "#ff00ff"))))
     )
    )

  (leaf whitespace
    :ensure t
    :diminish (global-whitespace-mode)
    :config
    (setq whitespace-style '(
                             ;; faceで可視化
                             face
                             ;; 行末
                             trailing
                             ;; タブ
                             tabs
                             ;; 表示のマッピング
                             space-mark
                             tab-mark
                             ))
    (setq whitespace-display-mappings
          '((tab-mark ?\t [?\u00BB ?\t] [?\\ ?\t])))
    (global-whitespace-mode t)
    )
  )

(leaf magit-setting
  :disabled
  :config
  (leaf magit
    :ensure t
    :if (executable-find "git")
    :bind
    ("C-x g" . magit-status)
    :config
    (eval-after-load "magit-log"
      '(progn
         (custom-set-variables
          '(magit-log-margin '(t "%Y-%m-%d %H:%M:%S" magit-log-margin-width t 18)))))
    (custom-set-faces
     '(magit-diff-added ((t (:background "#000000" :foreground "#91b831"))))
     '(magit-diff-context ((t (:background "#000000" :foreground "#80807f"))))
     '(magit-diff-context-highlight ((t (:background "#1c1c1c"))))
     '(magit-diff-hunk-heading-highlight ((t (:background "#6060b0" :foreground "#ffffff" :weight bold))))
     '(magit-diff-added-highlight ((t (:background "#008700" :foreground "#ffffff" :weight bold))))
     '(magit-diff-removed-highlight ((t (:background "#d70000" :foreground "#ffffff" :weight bold))))
     '(magit-diff-removed ((t (:background "#000000" :foreground "#b83c30"))))
     )
    )
  )

(leaf *complete
  :disabled
  :config
  (leaf company
    :ensure t
    :diminish t
    :config
    (global-company-mode)
    (setq company-auto-expand t)
    (setq company-idle-delay 0)
    (setq company-minimum-prefix-length 3)
    (setq company-selection-wrap-around t)

    (defun company--insert-candidate2 (candidate)
      (when (> (length candidate) 0)
        (setq candidate (substring-no-properties candidate))
        (if (eq (company-call-backend 'ignore-case) 'keep-prefix)
            (insert (company-strip-prefix candidate))
          (if (equal company-prefix candidate)
              (company-select-next)
            (delete-region (- (point) (length company-prefix)) (point))
            (insert candidate))
          )))
    (defun company-complete-common2 ()
      (interactive)
      (when (company-manual-begin)
        (if (and (not (cdr company-candidates))
                 (equal company-common (car company-candidates)))
            (company-complete-selection)
          (company--insert-candidate2 company-common))))

    (bind-keys
     :map company-active-map
     ("C-n" . company-select-next)
     ("C-p" . company-select-previous)
     ("TAB" . company-complete-common2)
     ("C-h" . nil)
     )
    (bind-key "M-i" 'company-other-backend)

    ;; なぜか bind-key だとエラーになったので define-keyで設定
    (define-key company-active-map (kbd "C-d") 'company-show-doc-buffer)
    )

  (leaf company-quickhelp
    :ensure t
    :config
    (company-quickhelp-mode t)
    )

  (leaf yasnippet
    :ensure t
    :diminish (yas-minor-mode)
    :config
    (leaf yasnippet-snippets :ensure t)
    (leaf consult-yasnippet
      :ensure t
      :bind
      ("C-c y" . consult-yasnippet))
    (yas-global-mode t)
    (bind-keys :map yas-minor-mode-map
               ("<backtab>" . yas-expand)
               ("TAB"       . nil)))
  )

(leaf *lsp
  :disabled
  :config
  (leaf lsp-mode
    :ensure t
    :bind
    ("M-t n" . lsp-rename)
    ("M-t b" . xref-pop-marker-stack)
    ("M-t w" . xref-find-definitions-other-window)
    :config
    (setq lsp-completion-enable t)
    (setq lsp-print-io nil)
    (setq lsp-auto-guess-root t)
    (setq lsp-response-timeout 10)
    (setq lsp-diagnostics-provider :none)
    ;;(setq lsp-prefer-flymake 'flymake)
    (setq lsp-file-watch-threshold 50000)
    (defun lsp--sort-completions (completions)
      (lsp-completion--sort-completions completions))
    (defun lsp--annotate (item)
      (lsp-completion--annotate item))
    (defun lsp--resolve-completion (item)
      (lsp-completion--resolve item))
    )

  (leaf lsp-ui
    :ensure t
    :hook (lsp-mode . lsp-ui-mode)
    :bind
    ("M-t s" . lsp-ui-peek-find-definitions)
    ("M-t r" . lsp-ui-peek-find-references)
    :config
    (setq lsp-ui-doc-enable t)
    (setq lsp-ui-doc-header t)
    (setq lsp-ui-doc-include-signature t)
    (setq lsp-ui-doc-position 'bottom)
    (setq lsp-ui-doc-max-width 150)
    (setq lsp-ui-doc-max-height 600)
    (setq lsp-ui-flycheck-enable nil)
    (setq lsp-ui-flymake-enable nil)
    (setq lsp-ui-sideline-enable nil)
    (setq lsp-ui-sideline-ignore-duplicate nil)
    (setq lsp-ui-sideline-show-symbol t)
    (setq lsp-ui-sideline-show-hover nil)
    (setq lsp-ui-sideline-show-diagnostics t)
    (setq lsp-ui-sideline-show-code-actions nil)
    (setq lsp-ui-imenu-enable nil)
    (setq lsp-ui-imenu-kind-position 'bottom)
    (setq lsp-ui-peek-enable nil)
    (setq lsp-ui-peek-list-width 60)
    (setq lsp-ui-peek-peek-height 30)
    (setq lsp-ui-peek-fontify 'on-demand)
    )
  )

(leaf *language
  :disabled
  :config
  (leaf python
    :ensure t
    :require t
    :config
    (leaf lsp-pyright
      :ensure t
      :config
      (add-hook
       'python-mode-hook
       '(lambda ()
          (require 'lsp-pyright)
          (lsp)))
      )

    (leaf poetry
      :ensure t
      :hook
      (python-mode-hook . poetry-tracking-mode)
      )

    (leaf *python-flycheck
      :disabled
      :config
      (add-hook
       'python-mode-hook
       '(lambda()
          (flycheck-select-checker 'python-flake8)))
      )

    (leaf *python-formatter
      :config
      (leaf python-black
        :ensure t
        )

      (leaf python-isort
        :ensure t
        )

      (defun my-python-formatter ()
        (interactive)
        (python-black-buffer)
        (python-isort-buffer)
        )

      (bind-key "M-t t" 'my-python-formatter python-mode-map)
      )
    )

  (leaf csv-mode
    :ensure t)

  (leaf yaml-mode
    :ensure t)

  (leaf emacs-lisp-mode
    :config
    (setq-default
       flycheck-disabled-checkers
       '(emacs-lisp)
       )
    )
  )

(provide 'init)
;;; init.el ends here
