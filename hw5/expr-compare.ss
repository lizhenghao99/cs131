#lang racket
;;; expr-compare
;;;
;;; need to compare:
;;;
;;; constant literals
;;; variable references
;;; procedure calls
;;; (quote datem)
;;; (lambda formals body)
;;; (if expr expr)

(define-namespace-anchor anc)
(define ns (namespace-anchor->namespace anc))

(define (builtin-test x y)
  (cond [(and (equal? x 'quote) (equal? y 'quote)) #t]
        [(not (equal? (equal? x 'if) (equal? y 'if))) #t]
        [(not (equal? (lambda-test x 'lambda) (lambda-test y 'lambda))) #t]
        [else #f]))

(define (lambda-test x y)
  (and (or (equal? x 'lambda) (equal? x 'λ))
           (or (equal? y 'lambda) (equal? y 'λ))))

(define (compare-lambda x y)
  (if (or (and (and (list? (cadr x)) (list? (cadr y)))
               (equal? (length (cadr x)) (length (cadr y))))
          (and (not (list? (cadr x))) (not (list? (cadr y)))))
      (if (or (equal? (car x) 'λ) (equal? (car y) 'λ))
          (cons 'λ (lambda-head-helper (cdr x) (cdr y)))
          (cons 'lambda
                (lambda-head-helper (cdr x) (cdr y))))
      (compare-constant x y)))

(define (lambda-head-helper x y)
  (let ([h (lambda-formal-matcher (car x) (car y))])
    (lambda-rest-helper x y h)))

(define (lambda-rest-helper x y h)
  (if (or (equal? x '()) (equal? y '()))
      '()
      (if (and (list? (car x)) (list? (car y)))
          (if (lambda-test (caar x) (caar y))
              (cons (compare-lambda (car x) (car y))
                    (lambda-rest-helper (cdr x) (cdr y) h))
              (cons (lambda-rest-helper (car x) (car y) h)
                    (lambda-rest-helper (cdr x) (cdr y) h)))
          (if (and (dict-has-key? h `(1 . ,(car x)))
                   (dict-has-key? h `(2 . ,(car y))))
              (cons (compare-constant (dict-ref h `(1 . ,(car x)))
                                      (dict-ref h `(2 . ,(car y))))
                    (lambda-rest-helper (cdr x) (cdr y) h))
              (if (dict-has-key? h `(1 . ,(car x)))
                  (cons (compare-constant (dict-ref h `(1 . ,(car x)))
                                          (car y))
                        (lambda-rest-helper (cdr x) (cdr y) h))
                  (if (dict-has-key? h `(2 . ,(car y)))
                       (cons (compare-constant (car x)
                                               (dict-ref h `(2 . ,(car y))))
                             (lambda-rest-helper (cdr x) (cdr y) h))
                       (cons (compare-constant (car x)
                                               (car y))
                             (lambda-rest-helper (cdr x) (cdr y) h))))))))
            
               
              ; (cons (dict-ref h (car x))
              ;       (lambda-rest-helper (cdr x) (cdr y) h))
              ; (cons (compare-constant (car x) (car y))
              ;       (lambda-rest-helper (cdr x) (cdr y) h))))))

(define (lambda-formal-matcher x y)
  (if (or (equal? x '()) (equal? y '()))
      '()
      (if (and (list? x) (list? y))
          (if (equal? (car x) (car y))
         ; (cons `(,(car x) . ,(car x))
              (lambda-formal-matcher (cdr x) (cdr y))
              (cons `((1 . ,(car x)) . ,(wrap-symbol (car x) (car y)))
                    (cons `((2 . ,(car y)) . ,(wrap-symbol (car x) (car y)))
                          (lambda-formal-matcher (cdr x) (cdr y)))))
          (if (equal? x y)
              '()
              (cons `((1 . ,x) . ,(wrap-symbol x y))
                    (cons `((2 . ,y) . ,(wrap-symbol x y)) '())
                    )))))

(define (wrap-symbol x y)
  (string->symbol (string-append (symbol->string x)
                                 (string-append "!"
                                                (symbol->string y)))))

(define (compare-constant x y)
  (if (equal? x y)
      x
      (if (and (equal? x #t) (equal? y #f))
          '%
          (if (and (equal? x #f) (equal? y #t))
              '(not %)
              `(if % ,x ,y)))))

(define (compare-list x y)
  (if (equal? (length x) (length y))
      (if (or (equal? x '()) (equal? y '()))
          '()
          (if (and (and (list? (car x)) (list? (car y)))
                   (lambda-test (caar x) (caar y)))
              (cons (compare-lambda (car x) (car y))
                    (compare-list (cdr x) (cdr y)))
              (if (lambda-test (car x) (car y))
                  (compare-lambda x y)
                        
                  (if (builtin-test (car x) (car y))
                      (compare-constant x y)
                      (cons(expr-compare (car x) (car y))
                           (compare-list (cdr x) (cdr y)))))))
      (compare-constant x y)))


(define (expr-compare x y)
  (if (and (list? x) (list? y))
      (compare-list x y)
      (compare-constant x y)))

(define (test-expr-compare x y)
  (and (equal?
        (eval `(let ((% #t)) ,(expr-compare x y)) ns)
        (eval x ns))
       (equal?
        (eval `(let ((% #f)) ,(expr-compare x y)) ns)
        (eval y ns))
       ))

(define test-expr-x '(cons #f
                           (cons ((lambda (a b c d) (list a b c d))
                                  1 2 '(a b)
                                  ((lambda (a) a) 10))
                                 (if (< 1 2) 'a 'b))))
(define test-expr-y '(cons #t
                           (cons ((λ (b a c e) (list a b c e))
                                  1 2 '(a c)
                                  ((lambda (e) e) 11))
                                 'c )))
