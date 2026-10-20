;;; bf.el --- Brainfuck Interpreter  -*- lexical-binding: t; -*-
;;; Commentary:
;; Educational programming to learn the Lisp language
;; The input op-code is not implemented, so at least `cat.bf' will not work.

;;; Code:

(defun my/read-file (filename)
  "Returns the content of FILENAME as a string."
  (with-temp-buffer
    (insert-file-contents-literally source-name)
    (buffer-string)
    )
  )

(defun input (c)
  "Inputs a caracter `C'."
  (list :kind :input :operand c)
  )

(defun output (c)
  "Prints a caracter `C'."
  (list :kind :output :operand c)
  )

(defun inc (c)
  "Increment value `C'."
  (list :kind :inc :operand c)
  )

(defun dec (c)
  "Decrement value `C'."
  (list :kind :dec :operand c)
  )

(defun left (c)
  "Decrement address value `C'."
  (list :kind :left :operand c)
  )

(defun right (c)
  "Increment address value `C'."
  (list :kind :right :operand c)
  )

(defun jz (c)
  "Jump if value `C' is zero."
  (list :kind :jz :operand c)
  )

(defun jnz (c)
  "Jump if value `C' is NON zero."
  (list :kind :jnz :operand c)
  )


(defun char-to-op (c)
  "Transform a source character `C' in one operation."
  ;;  (message "char-to-op(%s)" c)
  (cond
   ((= c ?,) #'input)
   ((= c ?.) #'output)
   ((= c ?+) #'inc)
   ((= c ?\-) #'dec)
   ((= c ?\<) #'left)
   ((= c ?\>) #'right)
   ((= c ?\[) #'jz)
   ((= c ?\]) #'jnz)
   (t nil))
  )

(mapcar #'char-to-op "+-<>[].,")

(eros-mode)

;; Test that the char-to-op returns the expected data.
(let ((assert (funcall (char-to-op ?+) 69) ))
  (unless (equal assert (list :kind :inc :operand 69))
    (error "ERROR char-to-op failed")
    )
  (message "INFO: ok")
  t
  )

(defun eval-inst (c &optional operand)
  "Evaluate one instruction `C' with its `OPERAND' (default 1)."
  (setq operand (or operand 1))
  (let ((op (char-to-op c)))
    (when op
      ;; (message "Op: %s, operand: %d -> ret: %s" op operand (funcall op operand))
      (funcall op operand)
      )))

(defun eval-inst-nil (c)
  "Evaluate one instruction `C'."
  (eval-inst c)
  )


;; Instruction parser
(defun parse-instructions (source cpu)
  "Transform Brainfuck `SOURCE' into some Lisp 'bytecode' for this `CPU'."
  (let ((bc (delq nil (mapcar #'eval-inst-nil source))))
    bc)
  )


(defun debug-jumps (ops)
  "Display jumps in `OPS'."
  (let ((i 0))
    (while (< i (length ops))
      ;; (message "op[%d]: %s" i (aref ops i))
      (pcase (plist-get (aref ops i) :kind)
        (:jnz (message "jnz %s" (plist-get (aref ops i) :operand)))
        (:jz  (message "jz  %s" (plist-get (aref ops i) :operand)))
        )
      (setq i (+ i 1))
      )))


(defun resolve-jumps (cpu)
  "Get code from `CPU' and resolve addresses for `JZ' and `JNZ' instructions."
  (let ((ops (gethash "exe" cpu)))
    (progn
      (let ((stack '()))
        (let ((i 0))
          (while (< i (length ops))
            (let ((op (aref ops i)))
              (pcase (plist-get op :kind)
                (:jz
                 (push i stack)
                 )
                (:jnz
                 (let ((jz-idx (pop stack)))
                   (let ((jz (aref ops jz-idx)))
                     (progn
                       (plist-put jz :operand i)
                       (plist-put op :operand jz-idx)
                       )
                     )
                   ))
                )
              )
            (setq i (+ i 1))
            )
          )
        )
      )
    )
  )


(defun todo (msg)
  "Some sort of panic function that displays `MSG'."
  (error "ERROR: %s" msg))


(defun execute (cpu)
  "Run the op-codes from this `CPU'."
  (with-temp-buffer
    (let (
          (ops (gethash "exe" cpu))
          (mem (gethash "mem" cpu))
          (pc (gethash "PC" cpu))
          (op nil)
          (head 0)
          )
      (while (< pc (length exe))
        (setq op (aref ops pc))
        ;; (message "Evaluating op: %s at pc: %d, head: %d, [head]: %d" op pc head (aref mem head))
        (pcase (plist-get op :kind)
          (:output (message "out char: %c"  (aref mem head)) (insert-char (aref mem head)))
          (:inc (aset mem head (+ (aref mem head) 1)))
          (:dec (aset mem head (- (aref mem head) 1)))
          (:left (setq head (- head 1)))
          (:right (setq head (+ head 1)))
          (:jz (when (equal 0 (aref mem head)) (setq pc (plist-get op :operand))))
          (:jnz (when (not (equal 0 (aref mem head))) (setq pc (plist-get op :operand))))
          (:input (todo "INPUT"))
          (t (todo "Default pcase"))
          )
        (setq pc (+ pc 1))
        )
      )
    (message "%s" (buffer-string))
    (buffer-string)
    )
  )

(defun main ()
  "Creates CPU, ask for input file, parse the source and runs the code."

  (setq source-name (read-file-name "Source filename:" (expand-file-name "./samples/") nil t))
  ;;  (message "filename: %s\n" source-name)


  ;; Read the source code from file
  (setq file-content
        (my/read-file source-name)
        )
  (message "content: %s" file-content)

  ;; Create virtual cpu and memory
  ;; Memory with 1024 slots
  (setq mem (make-vector 1024 0))


  ;; Create CPU
  (setq cpu (make-hash-table :test 'equal))
  ;; Set its memory
  (puthash "mem" mem cpu)
  ;; Set its program counter
  (puthash "PC" 0 cpu)

  ;; Parse source and set its executable section
  (message "Parsing instructions...")
  (setq exe-list (parse-instructions file-content cpu))

  
  ;; exe is a list: we want a vector or an array
  (message "Copying op-codes to exe...")
  (setq exe (make-vector (length exe-list) nil))
  (let ((i 0))
    (while (car exe-list)
      (aset exe i (car exe-list))
      (setq i (+ 1 i))
      (setq exe-list (cdr exe-list))
      )
    )
  (message "Building CPU...")

  (puthash "exe" exe cpu)
  ;; (#'eval-inst file-content)


  (setq ops (gethash "exe" cpu))
  ;; (setq op (aref ops 1))

  
  (message "Resolving jumps on CPU...")
  (resolve-jumps cpu)

  (message "Executing CPU...")
  (message "Result: %s" (execute cpu))
  )

(main)

;;; bf.el ends here
