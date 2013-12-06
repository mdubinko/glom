xquery version "1.0-ml";

(: Copyright 2013 MarkLogic Corporation.  All Rights Reserved. :)

module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";
import module namespace sem="http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
import module namespace graph = "http://github.com/mdubinko/glom/graph-crawl" at "/xquery/lib/graph-crawl.xqy";


declare variable $pfx := sem:prefixes("ntn: http://semanticbible.org/ns/2006/NTNames#");
declare variable $curie := function($s) { sem:curie-expand($s, $pfx) };

declare %test:setup function setup()
{
    let $urls := sem:rdf-load(xdmp:modules-root() || "test/testdata/NTN-individuals.owl")
    return ()
};

(: optional teardown function evaluated after all tests :)
declare %test:teardown function teardown()
{
    xdmp:directory("/triplestore/") ! xdmp:document-delete(xdmp:node-uri(.))
};


declare %test:case function transitive-closure-1() {
    let $result := graph:bfs($curie("ntn:Abraham"), 600, function($s) { cts:triples($s,$curie("ntn:parentOf"),())!sem:triple-object(.) } )
    let $count := fn:count($result)
    return assert:equal($count, 90)
};

declare %test:case function transitive-closure-2() {
    let $result := graph:bfs($curie("ntn:Paul"), 600, function($s) { cts:triples($s,($curie("ntn:collaboratesWith"),$curie("ntn:knows")),())!sem:triple-object(.) } )
    let $count := fn:count($result)
    return assert:equal($count, 102)
};

declare %test:case function shortest-path-1() {
    let $result := graph:shortest-path($curie("ntn:Abraham"), $curie("ntn:Jacob"), 50, function($s) { cts:triples($s, $curie("ntn:parentOf"), ()) } )
    let $count := fn:count($result)
    return assert:equal($count, 2)
};

declare %test:case function shortest-path-2() {
    let $result := graph:shortest-path($curie("ntn:Abraham"), $curie("ntn:Jesus"), 50, function($s) { cts:triples($s, (), ())[sem:triple-object(.) instance of sem:iri] } )
    let $_ := xdmp:log($result)
    let $count := fn:count($result)
    return assert:equal($count, 3)
};

declare %test:case function shortest-path-3() {
    let $result := graph:shortest-path($curie("ntn:Paul"), $curie("ntn:Fortunatus"), 50, function($s) { cts:triples($s, ($curie("ntn:collaboratesWith"),$curie("ntn:knows")), ()) } )
    let $_ := xdmp:log($result)
    let $count := fn:count($result)
    return assert:equal($count, 1)
};

