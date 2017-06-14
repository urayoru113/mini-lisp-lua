(define a
  (fun (a) 
       (define b (fun (b) (+ a b)))
       (define c (fun (b) (+ a b)))
       b))
(define b (a 1))
(fun () 1)
(b 2)
(b 3)
