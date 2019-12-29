(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile
  (require 'use-package))

(use-package delight
  :ensure t
  :after use-package)

(use-package emacs
  :custom
  (use-file-dialog nil)
  (use-dialog-box nil)
  (inhibit-splash-screen t)
  :config
  (menu-bar-mode -1)
  (tool-bar-mode -1)
;;  (scroll-bar-mode -1)
  (global-unset-key (kbd "C-z"))
  (global-unset-key (kbd "C-x C-z"))
  (global-unset-key (kbd "C-h h")))

(use-package emacs
  :custom
  (x-underline-at-descent-line t)
  (underline-minimum-offset 1)
  :config
  (defconst prot/fixed-pitch-font "Hack"
    "The default fixed-pitch typeface.")

  (defconst prot/fixed-pitch-params ":weight=regular:hintstyle=hintslight"
    "Fontconfig parameters for the fixed-pitch typeface.")

  ;;;; TODO is it okay to defconst there?
  ;; (defun prot/test-font-availaiblity ()
  ;;   "Checks for the availability of a desired monospace font"
  ;;   (when (member "Hack" (font-family-list))
  ;;     (defconst prot/fixed-pitch-font "Hack"
  ;;       "The default fixed-pitch typeface.")))

  (defun prot/font-family-size (family size)
    "Set frame font for FAMILY at SIZE."
    (set-frame-font (concat
                     family "-" (number-to-string size)
                     prot/fixed-pitch-params)
                    t t))

  (defun prot/laptop-fonts ()
    "Pass desired argument to `prot/font-sizes' for use on my
small laptop monitor."
    (interactive)
    (when window-system
      (prot/font-family-size prot/fixed-pitch-font 10.5)))

  (defun prot/desktop-fonts ()
    "Pass desired argument to `prot/font-sizes' for use on my
larger desktop monitor."
    (interactive)
    (when window-system
      (prot/font-family-size prot/fixed-pitch-font 11.5)))

  (defun prot/fonts-per-monitor ()
    "Choose between `prot/laptop-fonts' and `prot/desktop-fonts'
based on the width of the monitor.  The calculation is based on
the maximum width of my laptop's screen."
    (interactive)
    (when window-system
      (if (> (display-pixel-width) 1366)
          (prot/desktop-fonts)
        (prot/laptop-fonts))))

  :hook
  (after-init . prot/fonts-per-monitor))

(use-package server
  :hook (after-init . server-start))

(use-package desktop
  :custom
  (desktop-auto-save-timeout 300)
  (desktop-dirname "~/.emacs.d/")
  (desktop-base-file-name "desktop")
  (desktop-files-not-to-save nil)
  (desktop-globals-to-clear nil)
  (desktop-load-locked-desktop t)
  (desktop-missing-file-warning t)
  (desktop-restore-eager 3)
  (desktop-restore-frames nil)
  (desktop-save 'ask-if-new)
  :hook (after-init . (lambda () (desktop-save-mode 1))))

(use-package cus-edit
  :custom
  (custom-file "~/.emacs.d/custom.el")
  :hook (after-init . (lambda ()
                        (unless (file-exists-p custom-file)
                          (write-region "" nil custom-file))
                        (load custom-file))))

(use-package recentf
  :custom
  (recentf-save-file "~/.emacs.d/recentf")
  (recentf-max-menu-items 10)
  (recentf-max-saved-items 200)
  (recentf-show-file-shortcuts-flag nil)
  :config
  (recentf-mode 1)
  ;; Magic advice to rename entries in recentf when moving files in
  ;; dired.
  (defun rjs/recentf-rename-notify (oldname newname &rest args)
    (if (file-directory-p newname)
        (rjs/recentf-rename-directory oldname newname)
      (rjs/recentf-rename-file oldname newname)))

  (defun rjs/recentf-rename-file (oldname newname)
    (setq recentf-list
          (mapcar (lambda (name)
                    (if (string-equal name oldname)
                        newname
                      oldname))
                  recentf-list))
    recentf-cleanup)

  (defun rjs/recentf-rename-directory (oldname newname)
    ;; oldname, newname and all entries of recentf-list should already
    ;; be absolute and normalised so I think this can just test whether
    ;; oldname is a prefix of the element.
    (setq recentf-list
          (mapcar (lambda (name)
                    (if (string-prefix-p oldname name)
                        (concat newname (substring name (length oldname)))
                      name))
                  recentf-list))
    recentf-cleanup)

  (advice-add 'dired-rename-file :after #'rjs/recentf-rename-notify)

  (defun contrib/recentf-add-dired-directory ()
    "Include Dired buffers in the list.  Particularly useful when
combined with a completion framework's ability to display virtual
buffers."
    (when (and (stringp dired-directory)
               (equal "" (file-name-nondirectory dired-directory)))
      (recentf-add-file dired-directory))))

(use-package savehist
  :custom
  (savehist-file "~/.emacs.d/savehist")
  (history-length 1000)
  (savehist-save-minibuffer-history t)
  :config
  (savehist-mode 1))

(use-package saveplace
  :custom
  (save-place-file "~/.emacs.d/saveplace")
  :config
  (save-place-mode 1))

(use-package emacs
  :custom
  (backup-directory-alist '(("." . "~/.emacs.d/backup/")))
  (backup-by-copying t)
  (version-control t)
  (delete-old-versions t)
  (kept-new-versions 6)
  (kept-old-versions 2)
  (create-lockfiles nil))

(use-package ivy
  :ensure t
  :delight
  :custom
  (ivy-count-format "(%d/%d) ")
  (ivy-height-alist '((t lambda (_caller) (/ (window-height) 4))))
  (ivy-use-virtual-buffers t)
  (ivy-wrap nil)
  (ivy-re-builders-alist
   '((counsel-M-x . ivy--regex-fuzzy)
     (counsel-rg . ivy--regex-or-literal)
     (t . ivy--regex-plus)))
  (ivy-display-style 'fancy)
  (ivy-use-selectable-prompt t)
  (ivy-fixed-height-minibuffer nil)
  (ivy-initial-inputs-alist
   '((counsel-M-x . "")
     (counsel-describe-function . "^")
     (counsel-describe-variable . "^")))
  :config
  (ivy-set-occur 'counsel-fzf 'counsel-fzf-occur)
  (ivy-set-occur 'counsel-rg 'counsel-ag-occur)
  (ivy-set-occur 'ivy-switch-buffer 'ivy-switch-buffer-occur)
  (ivy-set-occur 'swiper 'swiper-occur)
  (ivy-set-occur 'swiper-isearch 'swiper-occur)
  (ivy-set-occur 'swiper-multi 'counsel-ag-occur)
  (ivy-mode 1)
  :hook
  (ivy-occur-mode . hl-line-mode)
  :bind (("<s-up>" . ivy-push-view)
		 ("<s-down>" . ivy-switch-view)
         ("C-S-r" . ivy-resume)
         :map ivy-occur-mode-map
         ("f" . forward-char)
         ("b" . backward-char)
         ("n" . ivy-occur-next-line)
         ("p" . ivy-occur-previous-line)
         ("<C-return>" . ivy-occur-press)))

(use-package amx
  :ensure t
  :disabled
  :after ivy
  :custom
  (amx-backend 'auto)
  (amx-save-file "~/.emacs.d/amx-items")
  (amx-history-length 50)
  (amx-show-key-bindings nil)
  :config
  (amx-mode 1))

(use-package prescient
  :ensure t
  :custom
  (prescient-history-length 200)
  (prescient-save-file "~/.emacs.d/prescient-items")
  (prescient-filter-method '(literal initialism fuzzy regexp))
  :config
  (prescient-persist-mode 1))

(use-package ivy-prescient
  :ensure t
  :after (prescient ivy)
  :custom
  (ivy-prescient-sort-commands
   '(:not swiper ivy-switch-buffer counsel-switch-buffer))
  (ivy-prescient-retain-classic-highlighting t)
  (ivy-prescient-enable-filtering t)
  (ivy-prescient-enable-sorting t)
  :config
  (ivy-prescient-mode 1))

(use-package counsel
  :ensure t
  :after ivy
  :custom
  (counsel-yank-pop-preselect-last t)
  (counsel-yank-pop-separator "\n—————————\n")
  (counsel-rg-base-command
   "rg -SHn --no-heading --color never --no-follow --hidden %s")
  (counsel-find-file-occur-cmd          ; TODO Simplify this
   "ls -a | grep -i -E '%s' | tr '\\n' '\\0' | xargs -0 ls -d --group-directories-first")
  :config
  (defun prot/counsel-fzf-rg-files (&optional input dir)
    "Run `fzf' in tandem with `ripgrep' to find files in the
present directory.  If invoked from inside a version-controlled
repository, then the corresponding root is used instead."
    (interactive)
    (let* ((process-environment
            (cons (concat "FZF_DEFAULT_COMMAND=rg -Sn --color never --files --no-follow --hidden")
                  process-environment))
           (vc (vc-root-dir)))
      (if dir
          (counsel-fzf input dir)
        (if (eq vc nil)
            (counsel-fzf input default-directory)
          (counsel-fzf input vc)))))

  (defun prot/counsel-fzf-dir (arg)
    "Specify root directory for `counsel-fzf'."
    (prot/counsel-fzf-rg-files ivy-text
                               (read-directory-name
                                (concat (car (split-string counsel-fzf-cmd))
                                        " in directory: "))))

  (defun prot/counsel-rg-dir (arg)
    "Specify root directory for `counsel-rg'."
    (let ((current-prefix-arg '(4)))
      (counsel-rg ivy-text nil "")))

  ;; TODO generalise for all relevant file/buffer counsel-*?
  (defun prot/counsel-fzf-ace-window (arg)
    "Use `ace-window' on `prot/counsel-fzf-rg-files' candidate."
    (ace-window t)
    (let ((default-directory (if (eq (vc-root-dir) nil)
                                 counsel--fzf-dir
                               (vc-root-dir))))
      (if (> (length (aw-window-list)) 1)
          (progn
            (find-file arg))
        (find-file-other-window arg))
      (balance-windows)))

  ;; Pass functions as appropriate Ivy actions (accessed via M-o)
  (ivy-add-actions
   'counsel-fzf
   '(("r" prot/counsel-fzf-dir "change root directory")
     ("g" prot/counsel-rg-dir "use ripgrep in root directory")
     ("a" prot/counsel-fzf-ace-window "ace-window switch")))

  (ivy-add-actions
   'counsel-rg
   '(("r" prot/counsel-rg-dir "change root directory")
     ("z" prot/counsel-fzf-dir "find file with fzf in root directory")))

  (ivy-add-actions
   'counsel-find-file
   '(("g" prot/counsel-rg-dir "use ripgrep in root directory")
     ("z" prot/counsel-fzf-dir "find file with fzf in root directory")))

  ;; Remove commands that only work with key bindings
  (put 'counsel-find-symbol 'no-counsel-M-x t)
  :bind (("M-x" . counsel-M-x)
         ("C-x C-f" . counsel-find-file)
         ("s-f" . counsel-find-file)
         ("s-F" . find-file-other-window)
         ("C-x b" . ivy-switch-buffer)
         ("s-b" . ivy-switch-buffer)
         ("C-x B" . counsel-switch-buffer-other-window)
         ("s-B" . counsel-switch-buffer-other-window)
         ("C-x d" . counsel-dired)
         ("s-d" . counsel-dired)
         ("s-D" . dired-other-window)
         ("C-x C-r" . counsel-recentf)
         ("s-r" . counsel-recentf)
         ("s-y" . counsel-yank-pop)
         ("C-h f" . counsel-describe-function)
         ("C-h v" . counsel-describe-variable)
         ("M-s r" . counsel-rg)
         ("M-s g" . counsel-git-grep)
         ("M-s z" . prot/counsel-fzf-rg-files)
         :map ivy-minibuffer-map
         ("C-r" . counsel-minibuffer-history)
         ("s-y" . ivy-next-line)        ; Avoid 2× `counsel-yank-pop'
         ("C-SPC" . ivy-restrict-to-matches)))

(use-package swiper
  :ensure t
  :after ivy
  :custom
  (swiper-action-recenter t)
  (swiper-goto-start-of-match t)
  (swiper-include-line-number-in-search t)
  :bind (("C-S-s" . swiper)
         ("M-s s" . swiper-multi)
         ("M-s w" . swiper-thing-at-point)))

(use-package ivy-rich
  :ensure t
  :custom
  (ivy-rich-path-style 'abbreviate)
  :config
  (setcdr (assq t ivy-format-functions-alist)
          #'ivy-format-function-line)
  (ivy-rich-mode 1))

(use-package ivy-posframe
  :ensure t
  :delight
  :custom
  (ivy-posframe-parameters
   '((left-fringe . 2)
     (right-fringe . 2)
     (internal-border-width . 2)
     (font . "Iosevka SS09-12:hintstyle=hintfull")))
  (ivy-posframe-height-alist
   '((swiper . 15)
     (swiper-isearch . 15)
     (t . 10)))
  (ivy-posframe-display-functions-alist
   '((complete-symbol . ivy-posframe-display-at-point)
     (swiper . nil)
     (swiper-isearch . nil)
     (t . ivy-posframe-display-at-frame-center)))
  :config
  (ivy-posframe-mode 1))

(use-package isearch
  :custom
  (search-whitespace-regexp ".*?")
  (isearch-lax-whitespace t)
  (isearch-regexp-lax-whitespace nil)
  :config
  (defun prot/isearch-mark-and-exit ()
    "Marks the current search string.  Can be used as a building
block for a more complex chain, such as to kill a region, or
place multiple cursors."
    (interactive)
    (push-mark isearch-other-end t 'activate)
    (setq deactivate-mark nil)
    (isearch-done))

  (defun stribb/isearch-region (&optional not-regexp no-recursive-edit)
    "If a region is active, make this the isearch default search
pattern."
    (interactive "P\np")
    (when (use-region-p)
      (let ((search (buffer-substring-no-properties
                     (region-beginning)
                     (region-end))))
        (message "stribb/ir: %s %d %d" search (region-beginning) (region-end))
        (setq deactivate-mark t)
        (isearch-yank-string search))))
  (advice-add 'isearch-forward-regexp :after 'stribb/isearch-region)
  (advice-add 'isearch-forward :after 'stribb/isearch-region)
  (advice-add 'isearch-backward-regexp :after 'stribb/isearch-region)
  (advice-add 'isearch-backward :after 'stribb/isearch-region)

  (defun contrib/isearchp-remove-failed-part-or-last-char ()
    "Remove failed part of search string, or last char if successful.
Do nothing if search string is empty to start with."
    (interactive)
    (if (equal isearch-string "")
        (isearch-update)
      (if isearch-success
          (isearch-delete-char)
        (while (isearch-fail-pos) (isearch-pop-state)))
      (isearch-update)))

  (defun contrib/isearch-done-opposite-end (&optional nopush edit)
    "End current search in the opposite side of the match.
Particularly useful when the match does not fall within the
confines of word boundaries (e.g. multiple words)."
    (interactive)
    (funcall #'isearch-done nopush edit)
    (when isearch-other-end (goto-char isearch-other-end)))
  :bind (("M-s M-o" . multi-occur)
         :map isearch-mode-map
              ("C-SPC" . prot/isearch-mark-and-exit)
              ("DEL" . contrib/isearchp-remove-failed-part-or-last-char)
              ("<C-return>" . contrib/isearch-done-opposite-end)))

(use-package anzu
  :ensure t
  :delight
  :custom
  (anzu-search-threshold 100)
  (anzu-replace-threshold nil)
  (anzu-deactivate-region nil)
  (anzu-replace-to-string-separator "")
  :config
  (global-anzu-mode 1)
  :bind (([remap isearch-query-replace] . anzu-isearch-query-replace)
         ([remap isearch-query-replace-regexp] . anzu-isearch-query-replace-regexp))
         ([remap query-replace] . anzu-query-replace)
         ([remap query-replace-regexp] . anzu-query-replace-regexp)
         ("M-s %" . anzu-query-replace-at-cursor))

(use-package wgrep
  :ensure t
  :custom
  (wgrep-auto-save-buffer t)
  (wgrep-change-readonly-file t))

(use-package dired
  :custom
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (dired-isearch-filenames 'dwim)
  (delete-by-moving-to-trash t)
  (dired-listing-switches "-AFhlv --group-directories-first")
  (dired-dwim-target t)
  :hook
  (dired-mode . dired-hide-details-mode)
  (dired-mode . hl-line-mode))

(use-package find-dired
  :after dired
  :custom
  (find-ls-option ;; applies to `find-name-dired'
   '("-ls" . "-AFhlv --group-directories-first"))
  (find-name-arg "-iname"))

(use-package async
  :ensure t)

(use-package dired-async
  :after (dired async)
  :config
  (dired-async-mode 1))

(use-package dired-narrow
  :ensure t
  :after dired
  :custom
  (dired-narrow-exit-when-one-left t)
  (dired-narrow-enable-blinking t)
  (dired-narrow-blink-time 0.3)
  :bind (:map dired-mode-map
         ("M-s n" . dired-narrow)))

(use-package wdired
  :after dired
  :commands (wdired-mode
             wdired-change-to-wdired-mode)
  :custom
  (wdired-allow-to-change-permissions t)
  (wdired-create-parent-directories t))

(use-package peep-dired
  :ensure t
  :after dired
  :bind (:map dired-mode-map
              ("P" . peep-dired))
  :custom
  (peep-dired-cleanup-on-disable t)
  (peep-dired-ignored-extensions
   '("mkv" "webm" "mp4" "mp3" "ogg" "iso")))

;; ;; use this for peep always on
;; (setq peep-dired-enable-on-directories t)

(use-package image-dired
  :custom
  (image-dired-external-viewer "xdg-open")
  (image-dired-thumb-size 80)
  (image-dired-thumb-margin 2)
  (image-dired-thumb-relief 0)
  (image-dired-thumbs-per-row 4)
  :bind (:map image-dired-thumbnail-mode-map
              ("<return>" . image-dired-thumbnail-display-external)))

(use-package dired-subtree
  :ensure t
  :after dired
  :bind (:map dired-mode-map
              ("<tab>" . dired-subtree-toggle)
              ("<C-tab>" . dired-subtree-cycle)
              ("<S-iso-lefttab>" . dired-subtree-remove)))

(use-package dired-x
  :after dired
  :bind (("C-x C-j" . dired-jump)
         ("s-j" . dired-jump)
         ("C-x 4 C-j" . dired-jump-other-window)
         ("s-J" . dired-jump-other-window))
  :hook
  (dired-mode . (lambda ()
                  (setq dired-clean-confirm-killing-deleted-buffers t))))

(use-package dired-rsync
  :ensure t
  :bind (:map dired-mode-map
              ("r" . dired-rsync)))

(use-package diredfl
  :ensure t
  :hook (dired-mode . diredfl-mode))

(use-package dired-git-info
  :ensure t
  :after dired
  :custom
  (dgi-commit-message-format "%h\t%s\t%cr")
  :bind (:map dired-mode-map
              (")" . dired-git-info-mode)))

(use-package magit
  :ensure t
  :bind (("C-c g" . magit-status)
         ("s-g" . magit-status)))

(use-package git-commit
  :after magit
  :custom
  (git-commit-fill-column 72)
  (git-commit-summary-max-length 50)
  (git-commit-known-pseudo-headers
   '("Signed-off-by"
     "Acked-by"
     "Modified-by"
     "Cc"
     "Suggested-by"
     "Reported-by"
     "Tested-by"
     "Reviewed-by"))
  (git-commit-style-convention-checks
   '(non-empty-second-line
     overlong-summary-line)))

(use-package magit-diff
  :after magit
  :custom
  (magit-diff-refine-hunk t))

(use-package uniquify
  :custom
  (uniquify-buffer-name-style 'post-forward-angle-brackets)
  (uniquify-strip-common-suffix t)
  (uniquify-after-kill-buffer-p t))

(use-package ibuffer
  :custom
  (ibuffer-expert t)
  (ibuffer-display-summary nil)
  (ibuffer-use-other-window nil)
  (ibuffer-show-empty-filter-groups nil)
  (ibuffer-movement-cycle nil)
  (ibuffer-default-sorting-mode 'filename/process)
  ;;;; NOTE built into the Modus themes
  ;; (ibuffer-deletion-face 'dired-flagged)
  ;; (ibuffer-marked-face 'dired-marked)
  (ibuffer-title-face 'font-lock-doc-face)
  (ibuffer-use-header-line t)
  (ibuffer-default-shrink-to-minimum-size nil)
  (ibuffer-saved-filter-groups
   '(("Main"
      ("Directories" (mode . dired-mode))
      ("Org" (mode . org-mode))
      ("Programming" (or
                      (mode . c-mode)
                      (mode . conf-mode)
                      (mode . css-mode)
                      (mode . emacs-lisp-mode)
                      (mode . html-mode)
                      (mode . mhtml-mode)
                      (mode . python-mode)
                      (mode . ruby-mode)
                      (mode . scss-mode)
                      (mode . shell-script-mode)
                      (mode . yaml-mode)))
      ("Markdown" (mode . markdown-mode))
      ("Magit" (or
                (mode . magit-blame-mode)
                (mode . magit-cherry-mode)
                (mode . magit-diff-mode)
                (mode . magit-log-mode)
                (mode . magit-process-mode)
                (mode . magit-status-mode)))
      ("Apps" (or
                   (mode . bongo-playlist-mode)
                   (mode . mu4e-compose-mode)
                   (mode . mu4e-headers-mode)
                   (mode . mu4e-main-mode)
                   (mode . elfeed-search-mode)
                   (mode . elfeed-show-mode)
                   (mode . mu4e-view-mode)))
       ("Emacs" (or
                 (name . "^\\*Help\\*$")
                 (name . "^\\*Custom.*")
                 (name . "^\\*Org Agenda\\*$")
                 (name . "^\\*info\\*$")
                 (name . "^\\*scratch\\*$")
                 (name . "^\\*Backtrace\\*$")
                 (name . "^\\*Messages\\*$"))))))
  :config
  (defun prot/ibuffer-multi ()
    "Spawn a new instance of `ibuffer' and give it a unique name
based on the directory of the current buffer."
    (interactive)
    (let* ((parent (if (buffer-file-name)
                       (file-name-directory (buffer-file-name))
                     default-directory))
           (name (car (last (split-string parent "/" t)))))
      (split-window-sensibly)
      (other-window 1)
      (ibuffer t "*Ibuffer [new]*")
      (rename-buffer (concat "*Ibuffer: " name "*"))))
  :hook
  (ibuffer-mode . hl-line-mode)
  (ibuffer-mode . (lambda ()
                     (ibuffer-switch-to-saved-filter-groups "Main")))
  :bind (("C-x C-b" . ibuffer)
         ("C-x C-S-b" . prot/ibuffer-multi) ; EXPERIMENTAL
         ))

(use-package dired-sidebar
  :ensure t
  :after dired
  :custom
  (dired-sidebar-close-sidebar-on-file-open nil)
  (dired-sidebar-delay-auto-revert-updates t)
  (dired-sidebar-stale-buffer-time-idle-delay 2)
  (dired-sidebar-disable-dired-collapse t)
  (dired-sidebar-display-autorevert-messages nil)
  (dired-sidebar-use-custom-font t)
  (dired-sidebar-face `(:height 0.85))
  (dired-sidebar-should-follow-file t)
  (dired-sidebar-cycle-subtree-on-click t)
  (dired-sidebar-follow-file-at-point-on-toggle-open t)
  (dired-sidebar-follow-file-idle-delay 2)
  (dired-sidebar-no-delete-other-windows t) ; Resist `delete-other-windows'
  (dired-sidebar-one-instance-p t)
  (dired-sidebar-open-file-in-most-recently-used-window t)
  (dired-sidebar-pop-to-sidebar-on-toggle-open t)
  (dired-sidebar-recenter-cursor-on-follow-file t)
  ;; (dired-sidebar-refresh-on-projectile-switch t)
  (dired-sidebar-refresh-on-special-commands t)
  (dired-sidebar-special-refresh-commands:
   '(dired-do-delete
     dired-do-rename
     dired-do-copy
     dired-do-flagged-delete
     dired-create-directory
     (delete-file . 5)
     (save-buffer . 5)
     magit-format-patch))
  (dired-sidebar-skip-subtree-parent t)
  (dired-sidebar-theme 'none)
  (dired-sidebar-width 35))

(use-package ibuffer-sidebar
  :ensure t
  :after ibuffer
  :custom
  (ibuffer-sidebar-use-custom-font t)
  (ibuffer-sidebar-face `(:height 0.85))
  (ibuffer-sidebar-pop-to-sidebar-on-toggle-open t)
  (ibuffer-sidebar-width 35)
  (ibuffer-sidebar-special-refresh-commands
   '((kill-buffer . 2)
     (find-file . 2)
     (delete-file . 2))))

(use-package emacs
  :config
  (defun prot/toggle-dired-ibuffer-sidebars ()
    "Toggle both `dired-sidebar' and `ibuffer-sidebar'."
    (interactive)
    (dired-sidebar-toggle-sidebar)
    (ibuffer-sidebar-toggle-sidebar)
    (balance-windows))
  :bind ("C-x C-d" . prot/toggle-dired-ibuffer-sidebars))

(use-package window
  :bind (("s-n" . next-buffer)
         ("s-p" . previous-buffer)
         ("s-o" . other-window)
         ("s-2" . split-window-below)
         ("s-3" . split-window-right)
         ("s-0" . delete-window)
         ("s-1" . delete-other-windows)
         ("s-5" . delete-frame)))

(use-package winner
  :hook (after-init . winner-mode)
  :bind (("<s-right>" . winner-redo)
         ("<s-left>" . winner-undo)))

(use-package windmove
  :bind (("M-s-h" . windmove-left))
         ("M-s-j" . windmove-down)
         ("M-s-k" . windmove-up)
         ("M-s-l" . windmove-right))

(use-package ace-window
  :ensure t
  :custom
  (aw-keys '(?h ?j ?k ?l ?y ?u ?i ?o ?p))
  (aw-scope 'frame)
  (aw-dispatch-always t)
  (aw-dispatch-alist
   '((?s aw-swap-window "Swap Windows")
     (?2 aw-split-window-vert "Split Window Vertically")
     (?3 aw-split-window-horz "Split Window Horizontally")
     (?? aw-show-dispatch-help)))
  (aw-minibuffer-flag t)
  (aw-ignore-current nil)
  (aw-display-mode-overlay t)
  (aw-background t)
  :config
  (ace-window-display-mode 1)
  :bind (("s-a" . ace-window)))

(use-package org
  :custom
  ;; agenda
  (org-directory "~/Org")
  (org-agenda-files '("~/Org/tasks.org" "~/Org/notes.org"))
  (org-default-notes-file "~/Org/notes.org")
  (org-agenda-window-setup 'current-window)
  (org-deadline-warning-days 7)
  (org-agenda-span 'month)
  (org-agenda-skip-scheduled-if-deadline-is-shown t)
  (org-agenda-sorting-strategy
   '((agenda deadline-up priority-down)
     (todo priority-down category-keep)
     (tags priority-down category-keep)
     ((search category-keep))))
  ;; capture, refile, todo
  (org-refile-targets '((org-agenda-files . (:maxlevel . 3))))
  (org-reverse-note-order nil)
  (org-refile-use-outline-path t)
  (org-refile-allow-creating-parent-nodes 'confirm)
  (org-refile-use-cache t)
  (org-todo-keywords
   '((sequence "TODO(t)" "|" "DONE(d)")
     (sequence "STUDY(s)" "WRITE(w)" "|" "POSTED(p)")
     (sequence "NOTE(n)" "|" "ARCHIVED(r)")))
  (org-highest-priority ?A)
  (org-lowest-priority ?C)
  (org-default-priority ?A)
  (org-capture-templates
   '(("t" "Task for the day" entry
      (file+headline "~/Org/tasks.org" "Tasks with a deadline")
      "* TODO [#A] %?\nDEADLINE: %t\n")
     ("l" "Link to Emacs buffer or file" entry
      (file+headline "~/Org/tasks.org" "Links to buffers/files")
      "* STUDY [#B] %?\nSCHEDULED: %t\n%a")
     ("L" "Link to full file system path" entry
      (file+headline "~/Org/tasks.org" "Links to buffers/files")
      "* STUDY [#B] %?\nSCHEDULED: %t\n%F")
     ("n" "Note" entry
      (file+headline "~/Org/tasks.org" "Notes with or without context")
      "* NOTE [#C] %?\nSCHEDULED: %t\n%i")))
  ;; code blocks
  (org-src-window-setup 'current-window)
  (org-src-fontify-natively t)
  (org-src-tab-acts-natively t)
  (org-confirm-babel-evaluate nil)
  (org-edit-src-content-indentation 0)
  ;; export
  (org-export-with-toc t)
  (org-export-headline-levels 8)
  (org-export-backends '(ascii html latex md))
  ;; log
  (org-log-done 'time)
  (org-log-redeadline nil)
  (org-log-reschedule nil)
  (org-read-date-prefer-future 'time)
  ;; general
  (org-special-ctrl-a/e 'reversed)
  (org-hide-emphasis-markers t)
  (org-structure-template-alist
   '(("s" "#+BEGIN_SRC\n?\n#+END_SRC")
     ("E" "#+BEGIN_SRC emacs-lisp\n?\n#+END_SRC")
     ("e" "#+BEGIN_EXAMPLE\n?\n#+END_EXAMPLE")
     ("q" "#+BEGIN_QUOTE\n?\n#+END_QUOTE")
     ("v" "#+BEGIN_VERSE\n?\n#+END_VERSE")
     ("V" "#+BEGIN_VERBATIM\n?\n#+END_VERBATIM")
     ("c" "#+BEGIN_CENTER\n?\n#+END_CENTER")
     ("C" "#+BEGIN_COMMENT\n?\n#+END_COMMENT")
     ("I" "#+INCLUDE: %file ?")))
  :config
  ;; Refresh org-agenda after rescheduling a task.
  (defun contrib/org-agenda-refresh ()
    "Refresh all `org-agenda' buffers."
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (derived-mode-p 'org-agenda-mode)
          (org-agenda-maybe-redo)))))

  (defadvice org-schedule (after refresh-agenda activate)
    "Refresh org-agenda."
    (contrib/org-agenda-refresh))

  ;; disable keys I rely on for other tasks
  (define-key org-mode-map (kbd "<C-return>") nil)
  (define-key org-mode-map (kbd "<C-S-return>") nil)
  :bind (("C-c a" . org-agenda)
         ("C-c c" . org-capture)
         ("C-c l" . org-store-link)))

(use-package htmlize
  :ensure t
  :after org
  :config
  (global-set-key (kbd "C-c o") (kbd "C-c C-e C-b h H")))

(use-package org-id
  :after org
  :custom
  (org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id)
  :config
  (defun contrib/org-get-id (&optional pom create prefix)
    "Get the CUSTOM_ID property of the entry at point-or-marker POM.
   If POM is nil, refer to the entry at point. If the entry does
   not have an CUSTOM_ID, the function returns nil. However, when
   CREATE is non nil, create a CUSTOM_ID if none is present
   already. PREFIX will be passed through to `org-id-new'. In any
   case, the CUSTOM_ID of the entry is returned."
    (interactive)
    (org-with-point-at pom
      (let ((id (org-entry-get nil "CUSTOM_ID")))
        (cond
         ((and id (stringp id) (string-match "\\S-" id))
          id)
         (create
          (setq id (org-id-new (concat prefix "h")))
          (org-entry-put pom "CUSTOM_ID" id)
          (org-id-add-location id (buffer-file-name (buffer-base-buffer)))
          id)))))

  (defun contrib/org-id-headlines ()
    "Add CUSTOM_ID properties to all headlines in the
   current file which do not already have one."
    (interactive)
    (org-map-entries (lambda ()
                       (contrib/org-get-id (point) 'create)))))

(use-package darkroom
  :ensure t
  :disabled
  :custom
  (darkroom-text-scale-increase 0))

(use-package org-bullets
  :ensure t
  :disabled
  :after org)

(use-package org-tree-slide
  :ensure t
  :disabled
  :after (org darkroom)
  :custom
  (org-tree-slide-breadcrumbs nil)
  (org-tree-slide-header nil)
  (org-tree-slide-slide-in-effect nil)
  (org-tree-slide-heading-emphasis nil)
  (org-tree-slide-cursor-init t)
  (org-tree-slide-modeline-display nil)
  (org-tree-slide-skip-done nil)
  (org-tree-slide-skip-comments t)
  (org-tree-slide-fold-subtrees-skipped t)
  (org-tree-slide-skip-outline-level 8)
  (org-tree-slide-never-touch-face t)
  :config
  (defun prot/org-presentation ()
    "Specifies conditions that should apply locally upon
activation of `org-tree-slide-mode'."
    (if (eq darkroom-tentative-mode nil)
        (progn
          (darkroom-tentative-mode 1)
          (org-bullets-mode 1)
          (org-indent-mode 1)
          (set-frame-font (concat
                           prot/fixed-pitch-font "-" (number-to-string 14)
                           prot/fixed-pitch-params)
                          t t)
          (setq cursor-type '(bar . 1)))
      (darkroom-tentative-mode -1)
      (org-bullets-mode -1)
      (org-indent-mode -1)
      (prot/fonts-per-monitor)
      (setq cursor-type 'box)))
  :bind (("<f9>" . org-tree-slide-mode)
         :map org-tree-slide-mode-map
         ("<C-right>" . org-tree-slide-move-next-tree)
         ("<C-left>" . org-tree-slide-move-previous-tree))
  :hook (org-tree-slide-mode . prot/org-presentation))

(use-package shell
  :commands (shell shell-command)
  :custom
  (ansi-color-for-comint-mode 'filter)
  :config
  (defun prot/shell-multi ()
    "Spawn a new instance of `shell' and give it a unique name
based on the directory of the current buffer."
    (interactive)
    (let* ((parent (if (buffer-file-name)
                       (file-name-directory (buffer-file-name))
                     default-directory))
           (name (car (last (split-string parent "/" t)))))
      (split-window-sensibly)
      (other-window 1)
      (shell "new")
      (rename-buffer (concat "*shell: " name "*"))))
  :bind (("<s-return>" . shell)
         ("<s-S-return>" . prot/shell-multi)))

(use-package term
  :commands term
  :custom
  (term-buffer-maximum-size 9999)
  (term-completion-autolist t)
  (term-completion-recexact t)
  (term-scroll-to-bottom-on-output t))

(use-package proced
  :commands proced
  :custom
  (proced-auto-update-flag t)
  (proced-auto-update-interval 1)
  (proced-descend t)
  (proced-filter 'user))

(use-package password-store
  :ensure t
  :commands (password-store-copy
             password-store-edit
             password-store-insert)
  :custom
  (password-store-time-before-clipboard-restore 30))

(use-package pass
  :ensure t)

(use-package elfeed
  :ensure t
  :commands elfeed
  :custom
  (elfeed-use-curl t)
  (elfeed-curl-max-connections 10)
  (elfeed-db-directory "~/.emacs.d/elfeed")
  (elfeed-enclosure-default-dir "~/Downloads")
  (elfeed-search-clipboard-type 'CLIPBOARD)
  (elfeed-search-title-max-width (current-fill-column))
  (elfeed-search-title-max-width 100)
  (elfeed-search-title-min-width 30)
  (elfeed-search-trailing-width 16)
  (elfeed-show-truncate-long-urls t)
  (elfeed-show-unique-buffers t)
  :config
  (defun prot/feeds ()
    "Loads a file with RSS/Atom feeds.  This file contains valid
syntax for use by the `elfeed' package."
    (let ((feeds "~/.emacs.d/feeds.el.gpg"))
      (when (file-exists-p feeds)
        (load-file feeds))))

  (defun ambrevar/elfeed-play-with-mpv ()
    "Play entry link with mpv."
    (interactive)
    (let ((entry (if (eq major-mode 'elfeed-show-mode)
                     elfeed-show-entry (elfeed-search-selected :single)))
          (quality-arg "")
          (quality-val (completing-read "Resolution: "
                                        '("480" "720" "1080")
                                        nil nil)))
      (setq quality-val (string-to-number quality-val))
      (message "Opening %s with height≤%s..."
               (elfeed-entry-link entry) quality-val)
      (when (< 0 quality-val)
        (setq quality-arg
              (format "--ytdl-format=[height<=?%s]" quality-val)))
      (start-process "elfeed-mpv" nil "mpv"
                     quality-arg (elfeed-entry-link entry))))
  :hook (after-init . prot/feeds)
  :bind (:map elfeed-search-mode-map
         ("v" . (lambda ()
                  (interactive)
                  (ambrevar/elfeed-play-with-mpv)
                  (elfeed-search-untag-all-unread)))
         ("w" . elfeed-search-yank)
         ("g" . elfeed-update)
         ("G" . elfeed-search-update--force)
         :map elfeed-show-mode-map
         ("v" . ambrevar/elfeed-play-with-mpv)
         ("w" . elfeed-show-yank)))

(use-package package
  :hook (package-menu-mode . hl-line-mode))

(use-package subword
  :delight
  :hook (prog-mode . subword-mode))

(use-package emacs
  :hook (text-mode . (lambda ()
                       (turn-on-auto-fill)
                       (delight 'auto-fill-function nil t)
                       (setq adaptive-fill-mode t))))

(use-package newcomment
  :custom
  (comment-empty-lines t)
  (comment-fill-column nil)
  (comment-multi-line t)
  (comment-style 'multi-line)
  :config
  (defun prot/comment-dwim (&optional arg)
    "Alternative to `comment-dwim': offers a simple wrapper
around `comment-line' and `comment-dwim'.

If the region is active, then toggle the comment status of the
region or, if the major mode defines as much, of all the lines
implied by the region boundaries.

Else toggle the comment status of the line at point."
    (interactive "*P")
    (if (use-region-p)
        (comment-dwim arg)
      (save-excursion
        (comment-line arg))))

  :bind (("C-;" . prot/comment-dwim)
         ("C-:" . comment-kill)
         ("M-;" . comment-indent)
         ("C-x C-;" . comment-box)))

(use-package flyspell
  :init
  (setq flyspell-issue-message-flag nil)
  (setq flyspell-issue-welcome-flag nil)
  (setq ispell-program-name "hunspell")
  (setq ispell-local-dictionary "en_GB")
  (setq ispell-local-dictionary-alist
        '(("en_GB"
           "[[:alpha:]]"
           "[^[:alpha:]]"
           "[']"
           nil
           ("-d" "en_GB,el_GR")
           nil
           utf-8)))
  :config
  (define-key flyspell-mode-map (kbd "C-;") nil)
  :hook
  (text-mode . turn-on-flyspell)
  (prog-mode . turn-off-flyspell))

(use-package markdown-mode
  :ensure t
  :mode ("\\.md\\'" . markdown-mode))

(use-package yaml-mode
  :ensure t
  :mode (("\\.yml\\'" . yaml-mode)
         ("\\.yaml\\'" . yaml-mode)))

(use-package emacs
  :mode (("offlineimaprc" . conf-mode)
         ("sxhkdrc" . conf-mode)
         ("Xmodmap" . conf-xdefaults-mode)
         ("template" . shell-script-mode)
         ("\\.rasi\\'" . css-mode)))

(use-package flycheck
  :ensure t
  :custom
  (flycheck-check-syntax-automatically '(save mode-enabled)))

(use-package flycheck-indicator
  :ensure t
  :after flycheck
  :hook (flycheck-mode-hook . flycheck-indicator-mode))

(use-package flycheck-posframe
  :ensure t
  :after flycheck
  :hook (flycheck-mode-hook . flycheck-posframe-mode))

(use-package package-lint
  :ensure t)

(use-package flycheck-package
  :ensure t
  :after (flycheck package-lint))

(use-package abbrev
  :delight
  :custom
  (abbrev-file-name "~/.emacs.d/abbrevs")
  (only-global-abbrevs nil)
  :config
  ;;;;;;;;;;;;;;;;;;;;;;
  ;; simple skeletons ;;
  ;;;;;;;;;;;;;;;;;;;;;;
  (define-skeleton protesilaos-com-skeleton
    "Adds a link to my website while prompting for a possible
  extension."
    "Insert website extension: "
    "https://protesilaos.com/" str "")
  (define-abbrev global-abbrev-table "meweb"
    "" 'protesilaos-com-skeleton)

  (define-skeleton protesilaos-gitlab-skeleton
    "Adds a link to my GitLab account while prompting for a
  possible extension.  Makes it easy to link to my various git
  repos."
    "Website extension: "
    "https://gitlab.com/protesilaos/" str "")
  (define-abbrev global-abbrev-table "megit"
    "" 'protesilaos-gitlab-skeleton)
  :hook
  (text-mode . abbrev-mode)
  (git-commit-mode . abbrev-mode))

(use-package dabbrev
  :custom
  (dabbrev-abbrev-char-regexp nil)
  (dabbrev-backward-only nil)
  (dabbrev-case-distinction nil)
  (dabbrev-case-fold-search t)
  (dabbrev-case-replace nil)
  (dabbrev-eliminate-newlines nil)
  (dabbrev-upcase-means-case-search t))

(use-package hippie-exp
  :after dabbrev
  :custom
  (hippie-expand-try-functions-list
   '(try-expand-dabbrev
     try-expand-dabbrev-visible
     try-expand-dabbrev-from-kill
     try-expand-dabbrev-all-buffers
     try-expand-list
     try-expand-list-all-buffers
     try-expand-line
     try-expand-line-all-buffers
     try-complete-file-name-partially
     try-complete-file-name
     try-expand-all-abbrevs))
  (hippie-expand-verbose t)
  :bind ("M-/" . hippie-expand))

(use-package company
  :ensure t
  :delight
  :custom
  (company-require-match nil)
  (company-tooltip-align-annotations t)
  (company-dabbrev-downcase nil)
  (company-show-numbers t)
  (company-selection-wrap-around t)
  (company-auto-complete nil)
  (company-minimum-prefix-length 3)
  (company-idle-delay 0.5)
  (company-tooltip-limit 10)
  (company-transformers
   '(company-sort-by-backend-importance
     company-sort-prefer-same-case-prefix
     company-sort-by-occurrence))
  :config
  (global-company-mode 1)
  (defun jcs--company-complete-selection--advice-around (fn)
    "Enable downcase only when completing the completion.  Advice
execute around `company-complete-selection' command."
    (let ((company-dabbrev-downcase t))
      (call-interactively fn)))
  (advice-add 'company-complete-selection :around #'jcs--company-complete-selection--advice-around)
  :bind (:map company-mode-map
              ("s-/" . company-manual-begin)
              :map company-active-map
              (("s-/" . company-other-backend)
               ("C-d" . company-show-doc-buffer)
               ("<tab>" . company-complete)
               ("<C-tab>" . company-complete-selection)
               ("C-n" . (lambda ()
                          (interactive)
                          (company-complete-common-or-cycle 1)))
               ("C-p" . (lambda ()
                          (interactive)
                          (company-complete-common-or-cycle -1))))))

(use-package company-prescient
  :ensure t
  :after (company prescient)
  :config
  (company-prescient-mode 1))

(use-package eldoc
  :config
  (global-eldoc-mode -1))

(use-package emacs
  :custom
  (custom-safe-themes t)
  :config
  (defun prot/modus-operandi ()
    "Enable some `modus-operandi' variables and load the theme."
    (setq modus-operandi-theme-slanted-constructs t
          modus-operandi-theme-bold-constructs t
          modus-operandi-theme-proportional-fonts nil
          modus-operandi-theme-scale-headings t
          modus-operandi-theme-scale-1 1.1
          modus-operandi-theme-scale-2 1.2
          modus-operandi-theme-scale-3 1.3
          modus-operandi-theme-scale-4 1.4)
    (load-theme 'modus-operandi t))

  (defun prot/modus-vivendi ()
    "Enable some `modus-vivendi' variables and load the theme."
    (setq modus-vivendi-theme-slanted-constructs t
          modus-vivendi-theme-bold-constructs t
          modus-vivendi-theme-proportional-fonts nil
          modus-vivendi-theme-scale-headings t
          modus-vivendi-theme-scale-1 1.1
          modus-vivendi-theme-scale-2 1.2
          modus-vivendi-theme-scale-3 1.3
          modus-vivendi-theme-scale-4 1.4)
    (load-theme 'modus-vivendi t))

  (defun prot/modus-themes-toggle ()
    "Simplistic toggle for my Modus Themes.  All it does is check
if `modus-operandi' (light version) is active and if so switch to
`modus-vivendi' (dark version).  Else it switches to the light
theme."
    (interactive)
    (if (eq (car custom-enabled-themes) 'modus-operandi)
        (prot/modus-vivendi)
      (prot/modus-operandi)))
  :bind ("<f5>" . prot/modus-themes-toggle)
  :hook (after-init . prot/modus-operandi))

(use-package emacs
  :custom
  (vc-follow-symlinks t)
  (frame-title-format '("%b %& GNU Emacs"))
  (echo-keystrokes 0.25)
  (auto-revert-verbose nil)
  (default-input-method "greek")
  (ring-bell-function 'ignore)
  :config
  (defalias 'yes-or-no-p 'y-or-n-p)
  (put 'narrow-to-region 'disabled nil)
  (put 'upcase-region 'disabled nil)
  (put 'downcase-region 'disabled nil)
  (put 'dired-find-alternate-file 'disabled nil)
  (put 'overwrite-mode 'disabled t))

(use-package paren
  :custom
  (show-paren-style 'mixed)
  (show-paren-when-point-in-periphery t)
  (show-paren-when-point-inside-paren nil)
  :config
  (show-paren-mode 1))

(use-package electric
  :custom
  (electric-pair-inhibit-predicate 'electric-pair-default-inhibit)
  (electric-pair-pairs '((8216 . 8217)
                         (8220 . 8221)
                         (171 . 187)))
  (electric-pair-skip-self 'electric-pair-default-skip-self)
  (electric-quote-context-sensitive t)
  (electric-quote-paragraph t)
  (electric-quote-string nil)
  :config
  (electric-indent-mode 1)
  (electric-pair-mode 1)
  (electric-quote-mode -1))

(use-package emacs
  :init
  (setq-default tab-always-indent 'complete)
  (setq-default tab-width 4)
  (setq-default indent-tabs-mode nil))

(use-package emacs
  :custom
  (cursor-type 'box)
  (cursor-in-non-selected-windows 'hollow)
  (x-stretch-cursor nil))

(use-package emacs
  :custom
  (fill-column 72)
  (sentence-end-double-space t)
  (sentence-end-without-period nil)
  (colon-double-space nil)
  :config
  (column-number-mode 1))

(use-package emacs
  :hook (before-save . delete-trailing-whitespace))

(use-package emacs
  :custom
  (save-interprogram-paste-before-kill t))

(use-package mouse
  :custom
  (mouse-drag-copy-region t)
  (make-pointer-invisible t)
  (mouse-wheel-progressive-speed t))
;;  :config
;;  (mouse-wheel-mode 1))

(use-package delsel
  :config
  (delete-selection-mode 1))

(use-package emacs
  :custom
  (scroll-preserve-screen-position t)
  (scroll-conservatively 1)
  (scroll-margin 0))

(use-package emacs
  :custom
  (repeat-on-final-keystroke t)
  (set-mark-command-repeat-pop t)
  :bind ("M-z" . zap-up-to-char))

(use-package emacs
  :config
  (defun prot/toggle-line-numbers ()
    "Toggles the display of line numbers.  Applies to all buffers."
    (interactive)
    (if (bound-and-true-p display-line-numbers-mode)
        (display-line-numbers-mode -1)
      (display-line-numbers-mode)))

  (defun prot/toggle-invisibles ()
    "Toggles the display of indentation and space characters."
    (interactive)
    (if (bound-and-true-p whitespace-mode)
        (whitespace-mode -1)
      (whitespace-mode)))
  :bind (("<f7>" . prot/toggle-line-numbers)
         ("<f8>" . prot/toggle-invisibles)))

(use-package broadcast
  :ensure t)

(use-package rainbow-blocks
  :ensure t
  :delight
  :commands rainbow-blocks-mode
  :custom
  (rainbow-blocks-highlight-braces-p t)
  (rainbow-blocks-highlight-brackets-p t)
  (rainbow-blocks-highlight-parens-p t))

(use-package rainbow-mode
  :ensure t
  :delight
  :commands rainbow-mode
  :custom
  (rainbow-ansi-colors nil)
  (rainbow-x-colors nil))

(use-package which-key
  :ensure t
  :delight
  :custom
  (which-key-show-early-on-C-h t)
  (which-key-idle-delay 10000)
  (which-key-idle-secondary-delay 0.05)
  (which-key-popup-type 'side-window)
  (which-key-show-prefix 'echo)
  (which-key-max-display-columns 3)
  (which-key-separator " ")
  (which-key-special-keys '("SPC" "TAB" "RET" "ESC" "DEL"))
  :config
  (which-key-mode 1))

(use-package emacs
  :config
  (defun bjm/align-whitespace (start end)
    "Align columns by whitespace"
    (interactive "r")
    (align-regexp start end "\\(\\s-*\\)\\s-" 1 0 t))

  (defun prot/copy-line ()
    "Copies the entirety of the current line."
    (interactive)
    (copy-region-as-kill (point-at-bol) (point-at-eol))
    (message "Current line copied"))

  (defun prot/multi-line-next ()
    "Moves the point 15 lines down."
    (interactive)
    (next-line 15))

  (defun prot/multi-line-prev ()
    "Moves the point 15 lines up."
    (interactive)
    (previous-line 15))

  (defun prot/kill-line-backward ()
    "Kill line backwards from the point to the beginning of the
line.  This will not remove the line."
    (interactive)
    (kill-line 0))

  (defun contrib/mark-whole-word (&optional arg allow-extend)
    "Like `mark-word', but selects whole words and skips over
whitespace.  If you use a negative prefix arg then select words
backward.  Otherwise select them forward.

If cursor starts in the middle of word then select that whole word.

If there is whitespace between the initial cursor position and the first
word (in the selection direction), it is skipped (not selected).

If the command is repeated or the mark is active, select the next NUM
words, where NUM is the numeric prefix argument.  (Negative NUM selects
backward.)"
    (interactive "P\np")
    (let ((num  (prefix-numeric-value arg)))
      (unless (eq last-command this-command)
        (if (natnump num)
            (skip-syntax-forward "\\s-")
          (skip-syntax-backward "\\s-")))
      (unless (or (eq last-command this-command)
                  (if (natnump num)
                      (looking-at "\\b")
                    (looking-back "\\b")))
        (if (natnump num)
            (left-word)
          (right-word)))
      (mark-word arg allow-extend)))

  (defun prot/new-line-below ()
    "Create a new line below the current one.  Move the point to
the absolute beginning.  Also see `prot/new-line-above'."
    (interactive)
    (end-of-line)
    (newline))

  (defun prot/new-line-above ()
    "Create a new line above the current one.  Move the point to
the absolute beginning.  Also see `prot/new-line-below'."
    (interactive)
    (beginning-of-line)
    (newline)
    (forward-line -1))

  (defun prot/transpose-chars ()
    "Always transposes the two characters before point.  There is
no 'dragging' the character forward.  This is the behaviour of
`transpose-chars' when point is at end-of-line."
    (interactive)
    (transpose-chars -1)
    (forward-char))

  (defun prot/transpose-or-swap-lines (arg)
    "If region is active, swap the line at mark (region
beginning) with the one at point (region end).  This leverages a
facet of the built-in `transpose-lines'.  Otherwise transpose the
current line with the one before it ('drag' line downward)."
    (interactive "p")
    (if (use-region-p)
        (transpose-lines 0)
      (transpose-lines arg)))

  (defun prot/transpose-or-swap-paragraphs (arg)
    "If region is active, swap the paragraph at mark (region
beginning) with the one at point (region end).  This leverages a
facet of the built-in `transpose-paragraphs'.  Otherwise
transpose the current paragraph with the one after it ('drag'
paragraph downward)."
    (interactive "p")
    (if (use-region-p)
        (transpose-paragraphs 0)
      (transpose-paragraphs arg)))

  (defun prot/transpose-or-swap-sentences (arg)
    "If region is active, swap the sentence at mark (region
beginning) with the one at point (region end).  This leverages a
facet of the built-in `transpose-sentences'.  Otherwise transpose
the sentence before point with the one after it ('drag' sentence
forward/downward).  Also `fill-paragraph' afterwards.

Note that, by default, sentences are demarcated by two spaces."
    (interactive "p")
    (if (use-region-p)
        (transpose-sentences 0)
      (transpose-sentences arg))
    (fill-paragraph))

  (defun prot/transpose-or-swap-words (arg)
    "If region is active, swap the word at mark (region
beginning) with the one at point (region end).

Otherwise, and while inside a sentence, this behaves as the
built-in `transpose-words', dragging forward the word behind the
point.  The difference lies in its behaviour at the end of a
line, where it will always transpose the word at point with the
one behind it (effectively the last two words).

This addresses two patterns of behaviour I dislike in the
original command:

1. When a line follows, `M-t' will transpose the last word of the
line at point with the first word of the line below.

2. While at the end of the line, `M-t' will not transpose the
last two words, but will instead move point one word backward.
To actually transpose the last two words, you need to invoke the
command twice."
    (interactive "p")
    (if (use-region-p)
        (transpose-words 0)
      (progn
        (if (eq (point) (point-at-eol))
            (progn
              (backward-word 1)
              (transpose-words 1)
              (forward-char 1))
          (transpose-words arg)))))

  (defun prot/unfill-region-or-paragraph (&optional region)
    "Join all lines in a region, if active, while respecting any
empty lines (so multiple paragraphs are not joined, just
unfilled).  If no region is active, operate on the paragraph.
The idea is to produce the opposite effect of both
`fill-paragraph' and `fill-region'."
    (interactive)
    (let ((fill-column most-positive-fixnum))
      (if (use-region-p)
          (fill-region (region-beginning) (region-end))
        (fill-paragraph nil region))))

    (defun prot/yank-replace-line-or-region ()
    "Replace the line at point with the contents of the last
stretch of killed text.  If the region is active, operate over it
instead.  This command can then be followed by the standard
`yank-pop' (default is bound to M-y)."
    (interactive)
    (if (use-region-p)
        (progn
          (delete-region (region-beginning) (region-end))
          (yank))
      (progn
        (delete-region (point-at-bol) (point-at-eol))
        (yank))))

;;;; NOTE: this is experimental and needs further refinements
;;   (defun prot/toggle-dedicated-window ()
;;     "Toggle current window as strongly dedicated to its buffer.
;;
;; Dedicated windows are not affected by actions that involve the
;; other window.  They remain in place."
;;     (interactive)
;;     (let ((buf (get-buffer-window (current-buffer))))
;;       (if (not (window-dedicated-p buf))
;;           (progn
;;             (set-window-dedicated-p buf t)
;;             (message "Added 'dedicated' flag to buffer"))
;;         (set-window-dedicated-p buf nil)
;;         (message "Removed 'dedicated' flag from buffer"))))

  :bind (("C-c C-=" . bjm/align-whitespace)
         ("C-S-w" . prot/copy-line)
         ("M-=" . count-words)
         ("s-k" . kill-this-buffer)
         ("C-S-k" . prot/kill-line-backward)
         ("C-S-SPC" . contrib/mark-whole-word)
         ("C-S-n" . prot/multi-line-next)
         ("C-S-p" . prot/multi-line-prev)
         ("<C-return>" . prot/new-line-below)
         ("<C-S-return>" . prot/new-line-above)
         ("M-SPC" . cycle-spacing)
         ("M-o" . delete-blank-lines)
         ("<f6>" . tear-off-window)
         ("C-t" . prot/transpose-chars)
         ("C-x C-t" . prot/transpose-or-swap-lines)
         ("C-S-t" . prot/transpose-or-swap-paragraphs)
         ("C-x t" . prot/transpose-or-swap-sentences)
         ("M-t" . prot/transpose-or-swap-words)
         ("M-Q" . prot/unfill-region-or-paragraph)
         ("C-S-y" . prot/yank-replace-line-or-region)))

(use-package crux
  :ensure t
  :commands (crux-transpose-windows
             crux-duplicate-current-line-or-region
             crux-rename-file-and-buffer
             crux-open-with)
  :bind (("s-t" . crux-transpose-windows)
         ("C-c w" . crux-duplicate-current-line-or-region)
         ("<C-f2>" . crux-rename-file-and-buffer)
         :map dired-mode-map
         ("<M-return>" . crux-open-with)))

(use-package goto-last-change
  :ensure t
  :commands goto-last-change
  :bind ("C-z" . goto-last-change))

(use-package emacs
  :commands contrib/diff-last-two-kills
  :config
  (defun contrib/diff-last-two-kills ()
    "Put the last two kills to temporary buffers and diff them."
    (interactive)
    (let ((old (generate-new-buffer "old"))
          (new (generate-new-buffer "new")))
      (set-buffer old)
      (insert (current-kill 0 t))
      (set-buffer new)
      (insert (current-kill 1 t))
      (diff old new)
      (kill-buffer old)
      (kill-buffer new))))

(use-package undo-tree
  :ensure t
  :init
  (global-undo-tree-mode))
