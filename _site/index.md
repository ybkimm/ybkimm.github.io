---
permalink: /
---

{% for post in site.post %}

* [{{ post.title }}]({{ post.url }}) - `{{ post.date | date_to_string }}`.

{% endfor %}

