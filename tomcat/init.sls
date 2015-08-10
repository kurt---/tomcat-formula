{% from "tomcat/map.jinja" import tomcat with context %}


include:
  - tomcat.package


remove-ROOT-Webapp-Folder:
  cmd.run:
  - name: curl http://{{ salt['pillar.get']('tomcat:manager:user') }}:{{ salt['pillar.get']('tomcat:manager:pass') }}@localhost:8080/manager/text/undeploy?path=/
  - onlyif: test -e /var/lib/tomcat7/webapps/ROOT/index.html
  - require:
    - pkg: {{ tomcat.name }}{{ tomcat.version }}

