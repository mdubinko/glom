(: Breadth-first search and related graph crawl algorithms :)

module namespace graph = "http://github.com/mdubinko/glom/graph-crawl";

(:~
: In-memory breadth-first search over a graph.
: For example, to implement transitive closure over a particular predicate $pred, use:
: graph:bfs($seeds, $limit, function($s) { cts:triples($s,$preds,())!sem:triple-object(.) })
: Note that the only reference this function has to the graph comes from the behavior of the $adjV function.
:
: @param $s the starting seeds, as IRIs found in a graph
: @param $limit the maximum number of generations to explore
: @param $adjV a function that returns adjacent nodes. It should have the signature adjV($iri as sem:iri*) as sem:iri*
: @return a list of sem:iri values representing graph nodes, in no particular guaranteed order.
:)
declare function graph:bfs($s as sem:iri*, $limit as xs:integer, $adjV) {
    let $visited := map:map()
    let $_ := $s ! map:put($visited, ., fn:true())
    return graph:bfs-inner($visited, $s, $limit, $adjV)
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
