{% from "tomcat/map.jinja" import tomcat with context %}

include:
  - oracle-java


{{ tomcat.name }}{{ tomcat.version }}:
  pkg:
    - installed
    - require:
      - sls: oracle-java
  service:
    - running
    - watch:
      - pkg: {{ tomcat.name }}{{ tomcat.version }}
      - file: tomcat_conf
    - require:
      - cmd: stop-tomcat-if-required





{% if grains.os == 'Arch' %}
tomcat_env:
  file.managed:
    - name: /etc/conf.d/{{ tomcat.name }}{{ tomcat.version }}
{% endif %}

tomcat_conf:
  file.append:
    {% if grains.os == 'FreeBSD' %}
    - name: /etc/rc.conf
    - text:
      - tomcat{{ tomcat.version }}_java_home="{{ salt['pillar.get']('java:home', '/usr') }}"
      - tomcat{{ tomcat.version }}_java_opts="-Djava.awt.headless=true -Xmx{{ salt['pillar.get']('java:Xmx', '3G') }} -XX:MaxPermSize={{ salt['pillar.get']('java:MaxPermSize', '256m') }}"
    {% elif grains.os == 'Arch' %}
    - name: /etc/conf.d/{{ tomcat.name }}{{ tomcat.version }}
    - text:
      - JAVA_HOME={{ salt['pillar.get']('java:home', '/usr/lib/jvm/java-7-openjdk') }}
      - JAVA_OPTS="-Djava.awt.headless=true -Xmx{{ salt['pillar.get']('java:Xmx', '3G') }} -XX:MaxPermSize={{ salt['pillar.get']('java:MaxPermSize', '256m') }}"
      {% if salt['pillar.get']('java:UseConcMarkSweepGC') %}
      - JAVA_OPTS="$JAVA_OPTS {{ salt['pillar.get']('java:UseConcMarkSweepGC') }}"
      {% endif %}
      {% if salt['pillar.get']('java:CMSIncrementalMode') %}
      - JAVA_OPTS="$JAVA_OPTS {{ salt['pillar.get']('java:CMSIncrementalMode') }}"
      {% endif %}
      {% if salt['pillar.get']('tomcat:security') %}
      - TOMCAT{{ tomcat.version }}_SECURITY={{ salt['pillar.get']('tomcat:security', 'no') }}
      {% endif %}
    - require:
      - file: tomcat_env
    {% else %}
    - name: /etc/default/tomcat{{ tomcat.version }}
    - text:
      - JAVA_HOME={{ salt['pillar.get']('java:home', '/usr') }}
      - JAVA_OPTS="-Djava.awt.headless=true -Xmx{{ salt['pillar.get']('java:Xmx', '3G') }} -XX:MaxPermSize={{ salt['pillar.get']('java:MaxPermSize', '256m') }} -Djava.net.preferIPv4Stack=true"
      {% if salt['pillar.get']('java:UseConcMarkSweepGC') %}
      - JAVA_OPTS="$JAVA_OPTS {{ salt['pillar.get']('java:UseConcMarkSweepGC') }}"
      {% endif %}
      {% if salt['pillar.get']('java:CMSIncrementalMode') %}
      - JAVA_OPTS="$JAVA_OPTS {{ salt['pillar.get']('java:CMSIncrementalMode') }}"
      {% endif %}
      {% if salt['pillar.get']('tomcat:security') %}
      - TOMCAT{{ tomcat.version }}_SECURITY={{ salt['pillar.get']('tomcat:security', 'no') }}
      {% endif %}
    {% endif %}

{% if grains.os != 'FreeBSD' %}
limits_conf:
  file.append:
    - name: /etc/security/limits.conf
    - text:
      - {{ tomcat.name }}{{ tomcat.version }} soft nofile {{ salt['pillar.get']('limit:soft', '64000') }}
      - {{ tomcat.name }}{{ tomcat.version }} hard nofile {{ salt['pillar.get']('limit:hard', '64000') }}
    - watch_in:
      - service: {{ tomcat.name }}{{ tomcat.version }}
{% endif %}

stop-tomcat-if-required:
  cmd.run:
    - name: pkill -f /usr/lib/jvm/default-java/bin/java
    - onlyif: pgrep -f /usr/lib/jvm/default-java/bin/java
    - require:
      - pkg: {{ tomcat.name }}{{ tomcat.version }}


/usr/share/tomcat7/common:
  file.directory:
    - user: {{ tomcat.name }}{{ tomcat.version }}
    - group: {{ tomcat.name }}{{ tomcat.version }}
    - require:
      - pkg: {{ tomcat.name }}{{ tomcat.version }}
    - require_in:
      - cmd: stop-tomcat-if-required

/usr/share/tomcat7/common/classes:
  file.directory:
    - user: {{ tomcat.name }}{{ tomcat.version }}
    - group: {{ tomcat.name }}{{ tomcat.version }}
    - require:
      - file: /usr/share/tomcat7/common
    - require_in:
      - cmd: stop-tomcat-if-required

/usr/share/tomcat7/server:
  file.directory:
    - user: {{ tomcat.name }}{{ tomcat.version }}
    - group: {{ tomcat.name }}{{ tomcat.version }}
    - require:
      - pkg: {{ tomcat.name }}{{ tomcat.version }}
    - require_in:
      - cmd: stop-tomcat-if-required

/usr/share/tomcat7/server/classes:
  file.directory:
    - user: {{ tomcat.name }}{{ tomcat.version }}
    - group: {{ tomcat.name }}{{ tomcat.version }}
    - require:
      - file: /usr/share/tomcat7/server
    - require_in:
      - cmd: stop-tomcat-if-required

/usr/share/tomcat7/shared:
  file.directory:
    - user: {{ tomcat.name }}{{ tomcat.version }}
    - group: {{ tomcat.name }}{{ tomcat.version }}
    - require:
      - pkg: {{ tomcat.name }}{{ tomcat.version }}
    - require_in:
      - cmd: stop-tomcat-if-required

/usr/share/tomcat7/shared/classes:
  file.directory:
    - user: {{ tomcat.name }}{{ tomcat.version }}
    - group: {{ tomcat.name }}{{ tomcat.version }}
    - require:
      - file: /usr/share/tomcat7/shared
    - require_in:
      - cmd: stop-tomcat-if-required

remove-ROOT-Webapp-Folder:
  cmd.run:
  - name: rm -rf /var/lib/tomcat7/webapps/ROOT && service tomcat7 restart
  - onlyif: test -e /var/lib/tomcat7/webapps/ROOT/index.html && curl http://{{ salt['pillar.get']('tomcat:manager:user') }}:{{ salt['pillar.get']('tomcat:manager:passwd') }}@localhost:8080/manager/text/undeploy?path=/
  - require:
    - pkg: {{ tomcat.name }}{{ tomcat.version }}

