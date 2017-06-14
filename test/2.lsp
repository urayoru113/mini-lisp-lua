(define a
  ((fun (a)
        (define b (fun (b) (+ a b)))
        b) 1))
(define b
  ((fun (c)
        (define b (fun (b) (+ c b (a 3))))
        b) 2))
(fun () 1)
