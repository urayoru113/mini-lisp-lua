(define a
  (fun (x) 
       (define x (- x 1))
       (if (> x 0) (a x) #f)
       (print-num x)
       #t))
(a 10)
