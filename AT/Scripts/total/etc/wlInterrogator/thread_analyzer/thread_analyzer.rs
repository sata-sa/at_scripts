#BEA Thread dump ruleset
#    Highlights content
#    Check thread_analizer.css

s/(- waiting .+) (<.+>)\ ?(\(.+\))/<span class=waiting_on>$1 $2<\/span> <span class=waiting_on_type>$3<\/span>/gm
s/(- locked) (<.+>)\ ?(\(.+\))/<span class=locked>$1 <u>$2<\/u><\/span> <span class=locked_type>$3<\/span>/gm
s/(tid=[0-9a-fx]+)\ /<span class=tid><u>$1<\/u><\/span>&nbsp;/gm
s/(nid=[0-9a-fx]+)\ /<span class=nid><u>$1<\/u><\/span>&nbsp;/gm
s/(prio=[0-9a-fx]+)\ /<span class=prio><u>$1<\/u><\/span>&nbsp;/gm
s/(lwp_id=[0-9a-fx]+)\ /<span class=prio><u>$1<\/u><\/span>&nbsp;/gm
s/(waiting for monitor entry)\ /<span class=state><u>$1<\/u><\/span>&nbsp;/gm
s/runnable/<span class=green>runnable<\/span>/g
s/in Object.wait\(\)/<span class=yellow>in Object.wait\(\)<\/span>/g
s/waiting for monitor entry/<span class=red>waiting for monitor entry<\/span>/g

s/thread_state_small>(<span.*?>)+runnable(<\/span>)+/thread_state_small_g>runnable/g
s/thread_state_small>(<span.*?>)+in Object.wait\(\)(<\/span>)+/thread_state_small_y>in Object.wait\(\)/g
s/thread_state_small>(<span.*?>)+waiting for monitor entry(<\/span>)+/thread_state_small_r>waiting for monitor entry/g
