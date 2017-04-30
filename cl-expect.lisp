;; use this to run programs. Returns a stream which can be used to manipulate the program.
(defun program-stream (program &optional args)
  (let ((process (sb-ext:run-program program args
				     :input :stream
				     :output :stream
				     :wait nil
				     :search t)))
    (when process
      (values
       (make-two-way-stream (sb-ext:process-output process)
			    (sb-ext:process-input process))
       process))))

;; following is from Rainer Joswig: http://stackoverflow.com/questions/18045842/appending-character-to-string-in-common-lisp
(defun make-adjustable-string (s)
  (make-array (length s)
	      :fill-pointer (length s)
	      :adjustable t
	      :initial-contents s
	      :element-type (array-element-type s)))

;;; this is too long and was very difficult to write and I guess it's very difficult to read so sorry about that
(defun s/read (stream &key (format-output t) (expect nil) (timeout-in-seconds 120))
  "format-output: t/nil/:quiet
   format-output controls what to display during execution, t: everything, :quiet: nothing, nil: nothing but progress
   expect: nil/list
   if expect is a list, then list elements (strings) are checked against last output so that appropriate action can be taken."
  
  ;; wait until there is some data to read
  (loop while (not (peek-char nil stream nil 'eof)))
  (let ((retval (make-adjustable-string ""))
	 (last-data-time (get-universal-time))
	 (notified nil)
	(char-count 0)
	(final-char nil))
	 ;;expect is a non-null list
	 (progn
	   (loop for c = (read-char-no-hang stream nil 'eof)
	      until (or (eq 'eof c)
			(some #'(lambda (x)
				  (eq t x))
			      (loop for ex in expect
				 collect
				   (let ((l-r (length retval))
					 (l-e (length ex)))
				     (and
				      (>= l-r l-e)
				      (equal ex (subseq retval (- (length retval)
								  (length ex)))))))))
	      do
		(if c
		    (progn
		      (incf char-count)
		      (setf last-data-time (get-universal-time))
		      (setf notified nil)
		      (vector-push-extend c retval)
		      
		      (if (and
			   format-output
			   (not (eq :quiet format-output)))
			  (format t "~a" c)
			  (progn
			    (when (and
				   (= 0 (mod char-count 10000))
				   (not (eq :quiet format-output)))
			     (format t ".")
			     (when (= 0 (mod char-count 1000000))
			       (format t "~%characters streamed so far: ~a~%" (write-to-string char-count)))))))
		    (when (and
			   (not notified)
			   (> (- (get-universal-time)
				 last-data-time)
			      timeout-in-seconds))
		      (format t "~%*** Waiting for input for more than 2 minutes, last data: ***~%~a~%*** End of data ***~%"
			      (if (> (length retval)
				     1000)
				  (subseq retval 0 1000)
				  retval))
		      (setf notified t)))))
     (finish-output nil)
     (setf final-char (read-char-no-hang stream nil 'eof))
     (values
      retval
      (let ((match nil))
	(loop for ex in expect do
	     (when
		 (let ((l-r (length retval))
		       (l-e (length ex)))
		   (when (and
			  (>= l-r l-e))
		     (equal ex (subseq retval (- (length retval)
						 (length ex))))))
	       (setf match ex)))
	(if match
	    match
	    final-char)))))

(defun s/write (stream txt &key (format-output nil))
  (format stream "~a~%" txt)
  (when format-output
    (format t "~a~%" txt)
    (finish-output nil))
  (finish-output stream))


(defun create-stream (program &optional args)
  (program-stream "unbuffer" (append (list "-p" program)
				     args)))
