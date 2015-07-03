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


/etc/{{ tomcat.name }}{{ tomcat.version }}/context.xml:
    file.managed:
        - source: salt://tomcat/files/context.xml
        - user: {{ tomcat.name }}{{ tomcat.version }}
        - group: {{ tomcat.name }}{{ tomcat.version }}
        - mode: 644
        - template: jinja
        - watch_in:
          - service: {{ tomcat.name }}{{ tomcat.version }}

mysql-connector:
  archive.extracted:
    - name: /usr/share/
    - source: http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.36.tar.gz
    - source_hash: md5=9a06f655da5d533a3c1b2565b76306c7
    - archive_format: tar
    - tar_options: z
    - if_missing: /usr/share/mysql-connector-java-5.1.36.jar


/usr/share/mysql-connector-java-5.1.36/mysql-connector-java-5.1.36.jar:
  file.symlink:
    - target: /usr/share/tomcat7/lib/mysql-connector-java-5.1.36.jar
    - require:
      - archive: mysql-connector



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