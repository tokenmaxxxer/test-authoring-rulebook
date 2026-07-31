#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: 테스트 코드 자체가 격리성·fixture 전략 면에서 좋은 설계인가"
USE_WHEN="USE_WHEN: 신규/기존 테스트 스위트를 설계·리뷰할 때"
PRODUCES=$'PRODUCES (required record fields): suite architecture note, fixture strategy, smell list (Meszaros catalog refs)\nWRITE_SCOPE: [\'test/**\']\nBOUNDARY CASE: if the work in front of you drifts outside `decides` above, stop and hand off per the arrow below — do not silently absorb another role\'s scope. Record the hand-off point in this role\'s record before opening the next role\'s session.'
HAND_OFF="HAND-OFF: 실제 실행 결과 관찰은 → execution-observation"
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
