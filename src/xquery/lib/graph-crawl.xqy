xquery version "1.0-ml";

(: Copyright 2013 MarkLogic Corporation.  All Rights Reserved. :)

(: Breadth-first search and related graph crawl algorithms :)

module namespace graph = "http://github.com/mdubinko/glom/graph-crawl";

(:~
: In-memory breadth-first search over a graph.
: For example, to implement transitive closure over a particular predicate $pred, use:
: graph:bfs($seeds, $limit, function($s) { cts:triples($s,$preds,())!sem:triple-object(.) })
: Note that the only reference this function has to the graph comes from the behavior of the $adjV function.
:
: @param $start the starting seeds, as IRIs found in a graph
: @param $limit the maximum number of generations to explore
: @param $adjV a function that returns adjacent nodes. It should have the signature adjV($iri as sem:iri*) as sem:iri*
: @return a list of sem:iri values representing graph nodes, in no particular guaranteed order.
:)
declare function graph:bfs($start as sem:iri*, $limit as xs:integer, $adjV) {
    let $visited := map:map()
    let $_ := $start ! map:put($visited, ., fn:true())
    return graph:bfs-inner($visited, $start, $limit, $adjV)
};

declare function graph:bfs-inner($visited as map:map, $queue as sem:iri*, $limit as xs:integer, $adjacentVertices) {
    if (fn:empty($queue) or $limit eq 0)
    then map:keys($visited) ! sem:iri(.) (: do something with results :)
    else
        let $thingstoEnqueue :=
            for $v in $adjacentVertices($queue)
            return
                if (map:contains($visited, $v))
                then ()
                else (map:put($visited, $v, fn:true()), $v)
        return graph:bfs-inner($visited, $thingstoEnqueue, $limit - 1, $adjacentVertices)
};

(:~
: In-memory shortest-path over a graph.
: Note that the only reference this function has to the graph comes from the behavior of the $adjT function.
: For each visited node, we store only the particular triple where we first visited it. Do minimal bookkeeping during traversal.
:
: @param $start the starting seeds, as IRIs found in a graph
: @param $end the ending nodes, as IRIs found in a graph
: @param $limit the maximum number of generations to explore
: @param $adjT a function that returns adjacent triples. It should have the signature adjT($iri as sem:iri*) as sem:triple*
: @return a sequence of triple values representing a path from $start to $end.
:)
declare function graph:shortest-path($start as sem:iri+, $end as sem:iri+, $limit as xs:integer, $adjT) {
    let $visited := map:map()
    let $_ := $start ! map:put($visited, string(.), .)
    return 
        if ($start = $end)
        then json:to-array($end[.=$start])
        else graph:shortest-path-inner($visited, $start, $end, $limit, $adjT)
};

declare function graph:shortest-path-inner($visited as map:map, $queue as sem:iri*, $end as sem:iri+, $limit as xs:integer, $adjacentTriples) {
    if (fn:empty($queue) or $limit eq 0)
    then () (: could not find path :)
    else
        let $found := json:array()
        let $thingstoEnqueue :=
            for $t in $adjacentTriples($queue)
            let $node := sem:triple-object($t)
            let $nodestr := string($node)
            return
                if (map:contains($visited, $nodestr))
                then ()
                else
                    if ($node = $end)
                    then json:array-push($found, $t)
                    else
                    (
                        map:put($visited, $nodestr, $t),
                        $node
                    )
        return
            let $finish := json:array-pop($found)
            return
                if (fn:exists($finish))
                then graph:extract-path($finish, $visited)
                else graph:shortest-path-inner($visited, $thingstoEnqueue, $end, $limit - 1, $adjacentTriples)
};

(: trace triples backwards until we hit the (seed) IRI :)
declare function graph:extract-path($current as sem:triple, $visited) {
    let $prev := map:get($visited, string(sem:triple-subject($current)))
    return
        if ($prev instance of sem:iri)
        then $current
        else (graph:extract-path($prev, $visited), $current)
};