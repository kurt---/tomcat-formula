include:
  - tomcat
  - tomcat.package

{% if grains.os != 'FreeBSD' %}
{% from "tomcat/map.jinja" import tomcat with context %}

# on archlinux tomcat manager is already in tomcat package
{% if grains.os != 'Arch' %}

{{ tomcat.manager }}:
  pkg:
    - installed
{% endif %}


extend:
  {{ tomcat.name }}{{ tomcat.version }}:
    service:
      - watch:
        - file: /etc/{{ tomcat.name }}{{ tomcat.version }}/tomcat-users.xml


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

{% endif %}
