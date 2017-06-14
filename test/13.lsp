(define a
  (fun (a)
       (fun (b) (+ a b))))
(define b (a 1))
(define c (a 2))
(print-num (b 3))
(print-num (c 4))
