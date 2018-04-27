# cl-expect
Common Lisp library that allows interfacing with OS programs. Requires SBCL to run, and unbuffer must be installed.

There are 3 defuns that allows creating, reading and writing program streams.

(create-stream) lets you create a program stream by giving the OS a program name and command line arguments.
(s/read) reads from the stream, optionally prints contents to the standard-output, or displays progress only (when long input is expected), and features an expect facility that stops reading when a certain string is present in the stream.
(s/write) writes to the stream.

In the following example we'll login to a host via ssh, query the uptime and then exit from the host.

    CL-USER> (let ((my-stream (create-stream "ssh" '("username@my-host.com"))))
         ;; we are expecting "password:" from the host when it requires the password
         (s/read my-stream :format-output t :expect '("password:"))
         (s/write my-stream "my-password")
         ;; we are expecting a prompt from the host where at the end there is a dollar sign:
         (s/read my-stream :format-output nil :expect '("$"))
         (s/write my-stream "uptime")
         (multiple-value-bind (retval expect)
             (s/read my-stream :format-output :quiet :expect '("$"))
           (format t "~%The return value of uptime was: ~a~%Expect is: ~a~%" retval expect))
         (s/write my-stream "exit")
         (s/read my-stream :format-output t :expect '("Connection to my-host.com closed."))
         (close my-stream))
    username@my-host.com's password:
    The return value of uptime was:  19:40:28 up  1:18,  2 users,  load average: 0.00, 0.00, 0.00
    ^[]0;username@localhost: ~^G^[[01;32musername@localhost^[[00m:^[[01;34m~^[[00m$
    Expect is: $
    logout
    Connection to my-host.com closed.
    T
    CL-USER> 

You may need to process the returned string by splitting, trimming, etc.
Also, you can give multiple expect strings and check the realized value like this:

    (let ((expect (nth-value 1 (s/read my-stream :format-output nil :expect '("expect-string-1" "expect-string-2")))))
      (cond ((string= expect "expect-string-1") (format t "expect-1 was received"))
             (string= expect "expect-string-2") (format t "expect-2 was received"))
             (equal expect 'eof) (format t "unexpected termination"))))
             
After tweaking (and using) it for a while, I decided to create two threads for the stream, and gensymed variables that can be used to read and write the input and output of the programs. In addition, there is now a "director" macro that binds the necessary symbols, and simplifies the communication process, thus stripping most of the bloat from the scripts.
An example is on the way...

Happy hacking!
