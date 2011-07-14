

(defun assembly-view()
  (local-set-key [(control ?x) (control ?a)] 'show-assembly-view)
)

(add-hook 'c++-mode-hook 'assembly-view)

(defun show-assembly-view()
	(interactive)
	"Show assembly commands corresponding to current line"
	(setq name (buffer-file-name))                   ; name of our [current] buffer / file.
	(setq line (substring (what-line) 5))            ; the line that we are working on

    ; Check if object file with same name exists. If it does, use it; if not, use executable.
	(if (file-exists-p (concat (file-name-sans-extension name) ".o"))
        (shell-command 
		(concat "analyzer.pl " 
		(concat (substring name 0 -4) ".o")
		" " 
		(concat "-l " line)))
      (shell-command
      (concat "analyzer.pl "
      (concat (substring name 0 -4))
      " "
      (concat "-l " line)))
    )
) 

