type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal

(* convert_grammar *)
let rec convert_helper old x = match old with
	| [] -> []
	| (first, second)::tail -> 
			if first = x
			then [second] @ convert_helper tail x
			else convert_helper tail x

let convert_grammar old = 
	(fst old, convert_helper (snd old))

(* parse_tree_leaves *)
let rec parse_tree_leaves_helper = function
	| [] -> []
	| Leaf x::rest -> [x] @ parse_tree_leaves_helper rest
	| Node (first, head::tail)::rest -> parse_tree_leaves_helper [head] 
									  @ parse_tree_leaves_helper tail 
									  @ parse_tree_leaves_helper rest
	| Node (_, [])::_ -> []

let parse_tree_leaves tree = 
	parse_tree_leaves_helper [tree]

(* make_matcher *)
let accept_all string = Some string
let accept_empty_suffix = function
   | _::_ -> None
   | x -> Some x

let getrule non gram = 
	(snd gram) non

let rec internal orig_frag rule gram ac frag = 
	tryrule frag orig_frag rule gram ac

and tryrule frag orig_frag rule gram ac = match rule with
	| [] -> None
	| []::rest -> ac frag
	| (head::tail)::rest -> match frag with
							| [] -> tryrule orig_frag orig_frag rest gram ac
							| h::t -> match head with
								| T ter ->
								if h = ter
								then tryrule t orig_frag (tail::rest) gram ac
								else tryrule orig_frag orig_frag rest gram ac

								| N non ->
									let result = tryrule (h::t) (h::t) 
										(getrule non gram) gram 
										(internal (h::t) (tail::[]) gram ac)
										in
									match result with
									| None -> 
									tryrule orig_frag orig_frag rest gram ac
									| Some x ->
										Some x 
								(*	tryrule x orig_frag (tail::rest) gram ac *)

let make_matcher grammar accept fragment = 
	tryrule fragment fragment (getrule (fst grammar) grammar) grammar accept


(* make_parser *)
let accept_tree = function
	| _::_  	-> None
	| x	 		-> Some (x,[])

let unwrap = function
	| None	-> failwith "unwrap error"
	| Some x -> x

let rec parserule frag orig_frag rule gram accept acc = match rule with
	| [] -> None
	| []::rest -> if accept frag = None then None
				 	else Some(frag, acc)
	| (head::tail)::rest -> match frag with
		| [] -> Some(frag, acc)
		| frag ->
			let headelement = parsehead frag frag head tail gram accept acc
			in if headelement = None 
			then parserule orig_frag orig_frag rest gram accept acc
			else 
			let newacc = acc @ (snd (unwrap headelement)) in
			parserule (fst (unwrap headelement)) orig_frag (tail::[]) gram accept newacc
		

and parsehead frag orig_frag head tail gram accept acc = match frag with
	| [] -> failwith "empty parsehead"
	| h::t ->
		match head with
			| T ter -> if ter = h then Some(t,[Leaf h]) else None
			| N non -> 
				let nodecontent = parserule (h::t) (h::t) 
									(getrule non gram) gram 
			(internal (h::t) (tail::[]) gram accept) [] in
				if nodecontent = None then None
				else Some (fst (unwrap nodecontent), [Node(non, snd(unwrap nodecontent))])

let make_parser grammar fragment = 
	match 
	parserule fragment fragment (getrule (fst grammar) grammar) grammar accept_tree []
	with
	| None -> None
	| Some x -> Some (Node(fst grammar, snd x))
