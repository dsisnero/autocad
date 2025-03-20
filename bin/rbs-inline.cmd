@echo off
watchexec -e rb rbs-inline --output='sig/generated' --opt-out --verbose lib
