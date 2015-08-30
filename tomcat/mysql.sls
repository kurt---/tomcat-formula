{% from "tomcat/map.jinja" import tomcat with context %}

include:
  - oracle-java
  - mysql.python
  - mysql.server
  - mysql.database
  - mysql.user
  - mysql.client


/etc/{{ tomcat.name }}{{ tomcat.version }}/context.xml:
  file.managed:
    - source: salt://tomcat/files/context.xml
    - user: {{ tomcat.name }}{{ tomcat.version }}
    - group: {{ tomcat.name }}{{ tomcat.version }}
    - mode: 644
    - template: jinja
    - watch_in:
      - service: {{ tomcat.name }}{{ tomcat.version }}
    - require:
      - archive: mysql-connector


/usr/share/tomcat7/lib/mysql-connector-java-5.1.36-bin.jar:
  file.symlink:
    - target: /usr/share/mysql-connector-java-5.1.36/mysql-connector-java-5.1.36-bin.jar
    - require:
      - archive: mysql-connector
    - watch_in:
      - service: {{ tomcat.name }}{{ tomcat.version }}

mysql-connector:
  archive.extracted:
    - name: /usr/share/
    - source: http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.36.zip
    - source_hash: md5=b7915ebc57cbf80b4d102bb7f7620d99
    - archive_format: zip
    - if_missing: /usr/share/mysql-connector-java-5.1.36
    - require:
      - sls: mysql.python
      - sls: mysql.server
      - sls: mysql.database
      - sls: mysql.user
      - sls: mysql.client
