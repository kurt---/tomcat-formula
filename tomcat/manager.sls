include:
  - tomcat
{% if grains.os != 'FreeBSD' %}
{% from "tomcat/map.jinja" import tomcat with context %}

# on archlinux tomcat manager is already in tomcat package
{% if grains.os != 'Arch' %}


/etc/ssh/banner:
  file.managed:
    - source: salt://ssh/banner


{{ tomcat.manager }}:
  pkg:
    - installed
{% endif %}

/etc/{{ tomcat.name }}{{ tomcat.version }}/tomcat-users.xml:
    file.managed:
        - source: salt://tomcat/files/tomcat-users.xml
        - user: root
        - group: {{ tomcat.name }}{{ tomcat.version }}
        - mode: 640
        - template: jinja
        - defaults:
            user: {{ salt['pillar.get']('tomcat:manager:user') }}
            passwd: {{ salt['pillar.get']('tomcat:manager:passwd') }}
        - watch_in:
          - service: {{ tomcat.name }}{{ tomcat.version }}


{% endif %}
