(in-package #:fast-generic-functions)

(defun parse-body (body)
  (let ((declarations '())
        (documentation nil))
    (loop for (item . rest) on body do
      (cond ((and (stringp item) (consp rest))
             (if (not documentation)
                 (setf documentation item)
                 (error "Multiple documentation strings in body: ~%~S~% and~%~S."
                        documentation item)))
            ((and (listp item) (eq (first item) 'declare))
             (push item declarations))
            (t
             (return-from parse-body
               (values
                (list* item rest)
                (reverse declarations)
                documentation)))))))

(defun block-name (function-name)
  (etypecase function-name
    ((and symbol (not null)) function-name)
    ((cons (eql setf) (cons symbol null)) (second function-name))))

(defun required-argument (name)
  (error "Required argument: ~S" name))

(defgeneric gensymify (object)
  (:method ((string string))
    (gensym (string-upcase (concatenate 'string string "-"))))
  (:method ((symbol symbol))
    (if (null (symbol-package symbol))
        ;; If we are dealing with uninterned symbols, we strip any
        ;; non-alphanumeric characters.  This has the effect that
        ;; gensymification of gensyms doesn't just add more and more
        ;; digits and hypens.
        (let ((name (symbol-name symbol)))
          (gensymify (subseq name 0 (1+ (position-if #'alpha-char-p name :from-end t)))))
        (gensymify (symbol-name symbol))))
  (:method ((object t))
    (gensymify (princ-to-string object))))

(defun null-lexical-environement-p (environment)
  (declare (ignorable environment))
  (or (null environment)
      #+sbcl (sb-c::null-lexenv-p environment)))
