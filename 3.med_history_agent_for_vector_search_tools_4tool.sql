-----------------------------------------
dual vector for med_history 
-----------------------------------------

-- vector column 추가
alter table med_history add SYMPT_PTT_V vector;
alter table med_history add PCR_REASON_V vector;
alter table med_history add IP_REASON_V vector;
alter table med_history add DGNSS_HNGNM_v vector;


-- med_history 테이블 정보

 이름                                    널?     유형
 ----------------------------------------- -------- ----------------------------
 PTT_NAME                                           VARCHAR2(10)
 VISIT_DTTM                                         VARCHAR2(20)
 SYMPT_PTT                                          VARCHAR2(1000)
 DGNSS_HNGNM                                        VARCHAR2(100)
 DR_NAME                                            VARCHAR2(10)
 PCR_REASON                                         VARCHAR2(1000)
 TREAT_CLASS                                        VARCHAR2(6)
 IP_DTTM                                            VARCHAR2(20)
 IP_REASON                                          VARCHAR2(1000)
 DCH_DTTM                                           VARCHAR2(20)
 SYMPT_PTT_V                                        VECTOR(*, *, DENSE)
 PCR_REASON_V                                       VECTOR(*, *, DENSE)
 IP_REASON_V                                        VECTOR(*, *, DENSE)
 DGNSS_HNGNM_V                                      VECTOR(*, *, DENSE)



-----------------------------------------
-- Emdedding
-----------------------------------------

UPDATE med_history
SET
    sympt_ptt_v = CASE
                    WHEN sympt_ptt IS NOT NULL
                    THEN VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING sympt_ptt AS data)
                    ELSE NULL
                  END,
    pcr_reason_v = CASE
                     WHEN pcr_reason IS NOT NULL
                     THEN VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING pcr_reason AS data)
                     ELSE NULL
                   END,
    ip_reason_v = CASE
                    WHEN ip_reason IS NOT NULL
                    THEN VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING ip_reason AS data)
                    ELSE NULL
                  END,
    DGNSS_HNGNM_V = CASE
                    WHEN DGNSS_HNGNM IS NOT NULL
                    THEN VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING DGNSS_HNGNM AS data)
                    ELSE NULL
                  END;

480 행이 업데이트되었습니다.

commit;

-----------------------------------------
-- 1-1 Create vector index & query test for sympt_ptt_v
-- 문진 내용 임베딩
-----------------------------------------

# drop index sympt_ptt_v_idx;


CREATE VECTOR INDEX sympt_ptt_v_idx 
ON med_history(sympt_ptt_v)
ORGANIZATION INMEMORY NEIGHBOR GRAPH
WITH DISTANCE COSINE
TARGET ACCURACY 95;

-- Vector query test

ACCEPT user_q1 PROMPT '질문을 입력하세요:' 

두통을 호소


SELECT
    ptt_name,
    visit_dttm,
    sympt_ptt,
    dr_name,
    ROUND(
        1 - VECTOR_DISTANCE(
                sympt_ptt_v,
                VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING '&user_q1' AS data),
                COSINE
            ),
        3
    ) AS similarity
FROM med_history
WHERE VECTOR_DISTANCE(
        sympt_ptt_v,
        VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING '&user_q1' AS data),
        COSINE
      ) <= 0.1  
ORDER BY similarity DESC
FETCH FIRST 10 ROWS ONLY;

-----------------------------------------
-- 1-2 Create vector index & query test for pcr_reason_v
-- 진료의 소견 및 처방 내용 임베딩
-----------------------------------------

# drop index pcr_reason_v_idx;

create vector index pcr_reason_v_idx 
on med_history(pcr_reason_v) 
ORGANIZATION INMEMORY NEIGHBOR GRAPH 
WITH DISTANCE COSINE
TARGET ACCURACY 95;

-- Vector query test 

ACCEPT user_q2 PROMPT '질문을 입력하세요:' 
감기 또는 폐렴 가능성을 진단

SELECT
    ptt_name,
    visit_dttm,
    sympt_ptt,
    pcr_reason,
    dr_name,
    ROUND(
        1 - VECTOR_DISTANCE(
              pcr_reason_v,
              VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING '&user_q2' AS data),
              COSINE
            ),
        3
    ) AS similarity
FROM med_history
WHERE VECTOR_DISTANCE(
        pcr_reason_v,
        VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING '&user_q2' AS data),
        COSINE
      ) <= 0.15  
ORDER BY similarity DESC
FETCH FIRST 10 ROWS ONLY;

-----------------------------------------
-- 1-3 Create vector index & query test for ip_reason_v
-- 입원 사유 임베딩
-----------------------------------------

# drop index ip_reason_v_idx;

create vector index ip_reason_v_idx 
on med_history(ip_reason_v) 
ORGANIZATION INMEMORY NEIGHBOR GRAPH 
WITH DISTANCE COSINE
TARGET ACCURACY 95;

-- Vector query test

ACCEPT user_q3 PROMPT '질문을 입력하세요:' 

혈당 조절을 위한 집중 치료 필요

SELECT
    ptt_name,
    ip_dttm,
    ip_reason,
    dr_name,
    ROUND(
    1 - VECTOR_DISTANCE(
        ip_reason_v,
        VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING '&user_q3' AS data),
        COSINE
        ),
    3
    ) AS similarity
FROM med_history
WHERE VECTOR_DISTANCE(
        ip_reason_v,
        VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING '&user_q3' AS data),
        COSINE
      ) <= 0.15  
ORDER BY similarity DESC
FETCH FIRST 10 ROWS ONLY;


-----------------------------------------
-- 1-4 Create vector index & query test for DGNSS_HNGNM_V
-- 문진 내용 임베딩
-----------------------------------------

# drop index DGNSS_HNGNM_V_IDX;


CREATE VECTOR INDEX DGNSS_HNGNM_V_IDX 
ON med_history(DGNSS_HNGNM_V)
ORGANIZATION INMEMORY NEIGHBOR GRAPH
WITH DISTANCE COSINE
TARGET ACCURACY 95;

-- Vector query test

ACCEPT user_q4 PROMPT '질문을 입력하세요:' 

급성 인두염


SELECT
            ptt_name,
            visit_dttm,
            sympt_ptt,
            dr_name,
            DGNSS_HNGNM,
    ROUND(
        1 - VECTOR_DISTANCE(
                DGNSS_HNGNM_V,
                VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING '&user_q4' AS data),
                COSINE
            ),
        3
    ) AS similarity
FROM med_history
WHERE VECTOR_DISTANCE(
        DGNSS_HNGNM_V,
        VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING '&user_q4' AS data),
        COSINE
      ) <= 0.1  
ORDER BY similarity DESC
FETCH FIRST 10 ROWS ONLY;

----------------------------------------
-- 2.Function for agent 생성 
----------------------------------------

----------------------------------------
-- 2-1 sympt_ptt column vector search
-- 문진 내용 검색
----------------------------------------

## DROP FUNCTION vector_search
##  FETCH FIRST 10 ROWS ONLY

CREATE OR REPLACE FUNCTION sympt_ptt_search (
    p_query IN VARCHAR2
) RETURN CLOB
IS
    l_result CLOB;
BEGIN
    DBMS_LOB.CREATETEMPORARY(l_result, TRUE);

    FOR r IN (
        SELECT
            ptt_name,
            visit_dttm,
            sympt_ptt,
            dr_name,
            ROUND(
                1 - VECTOR_DISTANCE(
                        sympt_ptt_v,
                        VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING p_query AS data),
                        COSINE
                    ),
                3
            ) AS similarity
        FROM med_history
        WHERE VECTOR_DISTANCE(
                sympt_ptt_v,
                VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING p_query AS data),
                COSINE
              ) <= 0.15   -- ✅ 유사도 85% 이상
        ORDER BY similarity DESC
    ) LOOP
        DBMS_LOB.APPEND(
            l_result,
            '환자이름: ' || r.ptt_name ||
            ', 외래일자: ' || r.visit_dttm ||
            ', 문진내용: ' || r.sympt_ptt ||
            ', 담당의사이름: ' || r.dr_name ||
            ', 질문유사도: ' || TO_CHAR(r.similarity) || CHR(10)
        );
        -- 컨텍스트 길이 제한
        IF DBMS_LOB.GETLENGTH(l_result) > 4000 THEN
            EXIT;
        END IF;
    END LOOP;

    RETURN l_result;
END;
/
-- PL/SQL vector_search 함수 테스트

SET SERVEROUTPUT ON;

DECLARE
    v_result CLOB;
BEGIN
    v_result := sympt_ptt_search('두통을 호소');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 4000, 1));
END;
/

------------------------------------------------------------
-- 2-2 pcr_reason column vector search
-- 진료의 소견 및 처방 내용 검색
------------------------------------------------------------

## DROP FUNCTION pcr_reason_search

CREATE OR REPLACE FUNCTION pcr_reason_search (
    p_query IN VARCHAR2
) RETURN CLOB
IS
    l_result CLOB;
BEGIN
    DBMS_LOB.CREATETEMPORARY(l_result, TRUE);

    FOR r IN (
        SELECT
            ptt_name,
            visit_dttm,
            sympt_ptt,
            pcr_reason,
            dr_name,
            ROUND(
                1 - VECTOR_DISTANCE(
                        pcr_reason_v,
                        VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING p_query AS data),
                        COSINE
                    ),
                3
            ) AS similarity
        FROM med_history
        WHERE VECTOR_DISTANCE(
                pcr_reason_v,
                VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING p_query AS data),
                COSINE
              ) <= 0.15   -- ✅ 유사도 85% 이상
        ORDER BY similarity DESC
    ) LOOP
        DBMS_LOB.APPEND(
            l_result,
            '환자이름: ' || r.ptt_name ||
            ', 외래일시: ' || r.visit_dttm ||
            ', 문진내용: ' || r.sympt_ptt ||
            ', 진료소견및처방: ' || r.pcr_reason ||
            ', 담당의사이름: ' || r.dr_name ||
            ', 질문유사도: ' || TO_CHAR(r.similarity) || CHR(10)
        );
        -- 컨텍스트 길이 제한
        IF DBMS_LOB.GETLENGTH(l_result) > 4000 THEN
            EXIT;
        END IF;
    END LOOP;

    RETURN l_result;
END;
/

-- PL/SQL vector_search 함수 테스트

SET SERVEROUTPUT ON;

DECLARE
    v_result CLOB;
BEGIN
    v_result := pcr_reason_search('감기 또는 폐렴 가능성을 진단');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 4000, 1));
END;
/


------------------------------------------------------------
-- 2-3 ip_reason column vector search
-- 입원 사유 검색
------------------------------------------------------------

## DROP FUNCTION pcr_reason_search

CREATE OR REPLACE FUNCTION ip_reason_search (
    p_query IN VARCHAR2
) RETURN CLOB
IS
    l_result CLOB;
BEGIN
    DBMS_LOB.CREATETEMPORARY(l_result, TRUE);

    FOR r IN (
        SELECT
            ptt_name,
            ip_dttm,
            ip_reason,
            dr_name,
            DGNSS_HNGNM,
            ROUND(
                1 - VECTOR_DISTANCE(
                        ip_reason_v,
                        VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING p_query AS data),
                        COSINE
                    ),
                3
            ) AS similarity
        FROM med_history
        WHERE VECTOR_DISTANCE(
                ip_reason_v,
                VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING p_query AS data),
                COSINE
              ) <= 0.15   -- ✅ 유사도 85% 이상
        ORDER BY similarity DESC
    ) LOOP
        DBMS_LOB.APPEND(
        l_result,
            '환자이름: ' || r.ptt_name ||
            ', 입원일시: ' || r.ip_dttm ||
            ', 입원사유: ' || r.ip_reason ||
            ', 담당의사이름: ' || r.dr_name ||
            ', 진단병명: ' || r.DGNSS_HNGNM ||
            ', 질문유사도: ' || TO_CHAR(r.similarity) || CHR(10)
        );
        -- 컨텍스트 길이 제한
        IF DBMS_LOB.GETLENGTH(l_result) > 4000 THEN
            EXIT;
        END IF;
    END LOOP;

    RETURN l_result;
END;
/

-- PL/SQL vector_search 함수 테스트

SET SERVEROUTPUT ON;


DECLARE
    v_result CLOB;
BEGIN
    v_result := ip_reason_search('피부 치료 및 혈당 조절');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 4000, 1));
END;
/

------------------------------------------------------------
-- 2-4 DGNSS_HNGNM column vector search
-- 진단명 검색
------------------------------------------------------------

## DROP FUNCTION pcr_reason_search

CREATE OR REPLACE FUNCTION DISEASE_NM_SEARCH (
    p_query IN VARCHAR2
) RETURN CLOB
IS
    l_result CLOB;
BEGIN
    DBMS_LOB.CREATETEMPORARY(l_result, TRUE);

    FOR r IN (
        SELECT
            ptt_name,
            visit_dttm,
            sympt_ptt,
            dr_name,
            DGNSS_HNGNM,
            ROUND(
                1 - VECTOR_DISTANCE(
                        DGNSS_HNGNM_v,
                        VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING p_query AS data),
                        COSINE
                    ),
                3
            ) AS similarity
        FROM med_history
        WHERE VECTOR_DISTANCE(
                DGNSS_HNGNM_v,
                VECTOR_EMBEDDING(MULTILINGUAL_E5_SMALL USING p_query AS data),
                COSINE
              ) <= 0.15   -- ✅ 유사도 85% 이상
        ORDER BY similarity DESC
    ) LOOP
        DBMS_LOB.APPEND(
            l_result,
            '환자이름: ' || r.ptt_name ||
            ', 내원일시: ' || r.visit_dttm ||
            ', 문진사유: ' || r.sympt_ptt ||
            ', 담당의사이름: ' || r.dr_name ||
            ', 진단병명: ' || r.DGNSS_HNGNM ||
            ', 질문유사도: ' || TO_CHAR(r.similarity) || CHR(10)
        );
        -- 컨텍스트 길이 제한
        IF DBMS_LOB.GETLENGTH(l_result) > 4000 THEN
            EXIT;
        END IF;
    END LOOP;

    RETURN l_result;
END;
/


-- PL/SQL vector_search 함수 테스트

SET SERVEROUTPUT ON;


DECLARE
    v_result CLOB;
BEGIN
    v_result := DISEASE_NM_SEARCH('머리 및 목의 심재성 2도 화상, 코(중격)');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_result, 4000, 1));
END;
/

------------------------------------------------
-- 3. Fulction Tool 생성
-- PL/SQL 기반의 Agent Tool 생성
------------------------------------------------

-----------------------------------------------
-- 3.1 SYMPT_PTT_VQ 생성
-- -- 문진 내용 검색 툴
-----------------------------------------------

-- 한글
BEGIN
  DBMS_CLOUD_AI_AGENT.DROP_TOOL('SYMPT_PTT_VQ');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  DBMS_CLOUD_AI_AGENT.CREATE_TOOL(
    tool_name   => 'SYMPT_PTT_VQ',
    attributes  =>
      '{' ||
      '"instruction": "이 툴은 med_history 테이블의 SYMPT_PTT_V 벡터컬럼에서 관련성 높은 상위 청크를 검색하는 용도로만 사용한다. ' ||
      '입력 파라미터 : {query}. ' ||
      '검색된 컨텍스트 텍스트만 반환하고, 요약하지 말며, 최종 답변을 제공하지 않는다. ' ||
      '이 툴은 환자가 문진 시 말한 증상을 검색하는 용도이다. ' ||
      '환자의 문진 내용을 찾아야 하는 경우 반드시 이 툴을 사용해야 한다. ",' ||
      '"function": "sympt_ptt_search"' ||
      '}',
    description => 'Vector search context tool'
  );
END;
/

-----------------------------------------------
-- 3.2 PCR_REASON_VQ 생성
-- 진료의 소견 및 처방 내용 검색 툴
----------------------------------------------
-- 한 글

BEGIN
  DBMS_CLOUD_AI_AGENT.DROP_TOOL('PCR_REASON_VQ');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/


BEGIN
  DBMS_CLOUD_AI_AGENT.CREATE_TOOL(
    tool_name   => 'PCR_REASON_VQ',
    attributes  => 
     '{' ||
      '"instruction": "이 툴은 med_history 테이블의 PCR_REASON_V 벡터컬럼에서 관련성 높은 상위 청크를 검색하는 용도로만 사용한다. ' ||
      '입력 파라미터 : {query}. ' ||
      '검색된 컨텍스트 텍스트만 반환하고, 요약하지 말며, 최종 답변을 제공하지 않는다. ' ||
      '이 툴은 의사가 환자의 증상에 따라 판단한 처방 사유를 찾는 용도이다. ' ||
      '의사의 진단 및 처방 사유를 찾아야 하는 경우 반드시 이 툴을 사용해야 한다. ",' ||
      '"function": "pcr_reason_search"' ||
      '}',
    description => 'Vector search context tool'
  );
END;
/

-------------------------------------------------
-- 3.3 ip_reason tool 생성
-- 입원 사유 검색 툴
------------------------------------------------
-- 한글
BEGIN
  DBMS_CLOUD_AI_AGENT.DROP_TOOL('IP_REASON_VQ');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/


BEGIN
  DBMS_CLOUD_AI_AGENT.CREATE_TOOL(
    tool_name   => 'IP_REASON_VQ',
    attributes  => 
     '{' ||
      '"instruction": "이 툴은 med_history 테이블의 ip_reason_V 벡터컬럼에서 관련성 높은 상위 청크를 검색하는 용도로만 사용한다. ' ||
      '입력 파라미터 : {query}.' ||
      '검색된 컨텍스트 텍스트만 반환하고, 요약하지 말며, 최종 답변을 제공하지 않는다. ' ||
      '이 툴은 의사가 환자를 병원에 입원시킨 이유 또는 사유를 찾는 용도이다. ' ||
      '환자가 입원한 사유를 찾아야 하는 경우 반드시 이 툴을 사용해야 한다. ",' ||
      '"function": "ip_reason_search"' ||
      '}',
    description => 'Vector search context tool'
  );
END;
/

-----------------------------------------------
-- 3.4 DISEASE_NM_VQ 생성
-- 진단명 검색 툴
-----------------------------------------------

-- 한글

BEGIN
  DBMS_CLOUD_AI_AGENT.DROP_TOOL('DISEASE_NM_VQ');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  DBMS_CLOUD_AI_AGENT.CREATE_TOOL(
    tool_name   => 'DISEASE_NM_VQ',
    attributes  =>
      '{' ||
      '"instruction": "이 툴은 med_history 테이블의 DGNSS_HNGNM_V 벡터컬럼에서 관련성 높은 상위 청크를 검색하는 용도로만 사용한다. ' ||
      '입력 파라미터 : {query}. ' ||
      '검색된 컨텍스트 텍스트만 반환하고, 요약하지 말며, 최종 답변을 제공하지 않는다. ' ||
      '이 툴은 환자가 진단 받은 진단명으로 검색하는 용도이다. ' ||
      '진단명으로 환자의 정보를 찾아야 하는 경우 반드시 이 툴을 사용해야 한다. ",' ||
      '"function": "DISEASE_NM_SEARCH"' ||
      '}',
    description => 'Vector search context tool'
  );
END;
/


-----------------------------------------------
-- 4. Task 생성
-- 질문에 대한 검색 툴을 라우팅하는 Task. 증상 질문은 SYMPT_PTT_VQ, 처방 사유 질문은 PCR_REASON_VQ, 입원사유는 IP_REASON_VQ tool, 진단명은 DISEASE_NM_VQ로 라우팅
-----------------------------------------------
-- 한글
BEGIN
  DBMS_CLOUD_AI_AGENT.DROP_TASK('MED_SEARCH_TASK');
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  DBMS_CLOUD_AI_AGENT.CREATE_TASK(
    task_name => 'MED_SEARCH_TASK',
    attributes =>
      '{' ||
      '"instruction": "당신의 역할은 사용자의 질문을 아래 4가지 카테고리 중 정확히 하나로 분류하고 반드시 해당하는 tool 하나만 선택하는 것이다. ' ||
      '고객 질문 {query}.' ||
      '사용 가능한 tool: SYMPT_PTT_VQ(증상), PCR_REASON_VQ(처방/진단 사유), IP_REASON_VQ(입원 사유), DISEASE_NM_VQ(진단명). ' ||
      '1. 증상: 문진 내용, 환자가 느끼는 증상, 통증, 불편, 호소 내용 (예: 두통, 기침, 열, 어지러움, 복통, 호흡곤란) → SYMPT_PTT_VQ. ' ||
      '2. 처방/진단 사유: 의사가 판단한 진단 이유, 치료 또는 처방의 근거, 질병 가능성 판단 (예: 감기 가능성 진단, 폐렴 의심, 항생제 처방 이유) → PCR_REASON_VQ. ' ||
      '3. 입원 사유: 입원하게 된 이유, 입원 필요성, 치료/관리 목적 입원 (예: 혈당 조절 위해 입원, 집중 치료 필요, 수술 후 회복) → IP_REASON_VQ. ' ||
      '4. 진단명: 병명, 질병 이름 자체, 확정된 진단 결과 (예: 급성 인두염, 폐렴 환자, 당뇨병) → DISEASE_NM_VQ. ' ||
      '강제 규칙: 반드시 4개 중 하나의 tool만 선택해야 한다. 두 개 이상 선택 금지. 새로운 tool 생성 금지. FrequencyAnalyzer 같은 tool 절대 사용 금지. tool 미선택 금지. ' ||
      '출력 규칙: 선택한 tool만 호출하고 설명, 요약, 추가 텍스트를 생성하지 않는다.",' ||
      '"tools":["SYMPT_PTT_VQ","PCR_REASON_VQ","IP_REASON_VQ","DISEASE_NM_VQ"],' ||
      '"enable_human_tool":false' ||
      '}',
    description => 'Strict routing for tools'
  );
END;
/

------------------------------------------
-- 4-1. Select AI 프로파일 생성
-- 
------------------------------------------
-- Agent에서 사용할 AI 프로파일
BEGIN
  BEGIN
  -- 있으면 삭제 (force => true)
  DBMS_CLOUD_AI.DROP_PROFILE(
    profile_name => 'MED_RAG_PROFILE',
    force        => TRUE
  );
  END;

  -- 생성
  DBMS_CLOUD_AI.CREATE_PROFILE(
    profile_name => 'MED_RAG_PROFILE',
    attributes   => '{
      "provider":"OPENAI",
      "provider_endpoint": "http://service-ollama",
      "model": "exaone3.5-32k",
      "max_tokens": 4096,
      "temperature": 0,
      "object_list": [
        {"owner": "LABADMIN", "name": "MED_HISTORY"}
      ]
    }',
    status       => 'enabled',
    description  => 'Select AI profile for Med History'
  );
END;
/

----------------------------------------
-- 5. Agnet 생성
-- 환자 정보 검색 Agent
---------------------------------------

-- 한글

BEGIN
    DBMS_CLOUD_AI_AGENT.DROP_AGENT('MED_RAG_AGENT', force => TRUE);
  EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
  DBMS_CLOUD_AI_AGENT.CREATE_AGENT(
    agent_name => 'MED_RAG_AGENT',
    attributes => 
    '{' ||
      '"profile_name": "MED_RAG_PROFILE", ' ||
      '"role": "당신은 med_history를 위한 의료 기록 검색 에이전트이다. ' ||
      '반드시 주어진 tool만 사용한다. ' ||
      '허용되지 않은 tool을 생성하거나 사용하지 않는다. ' ||
      '항상 tool을 호출하여 결과만 반환한다. ' ||
      '추론하거나 임의로 분석하지 않는다. ' ||
      '최종 답변은 반드시 Markdown 형식으로 출력한다. "' ||
    '}',
    description => 'med_history 검색용 에이전트'
  );
END;
/

----------------------------------------------
-- 6 Team 생성
-- MED_RAG_TEAM 팀 생성.
---------------------------------------------

BEGIN
  DBMS_CLOUD_AI_AGENT.DROP_TEAM(team_name => 'MED_RAG_TEAM', force => TRUE);
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
-- Create team
BEGIN
  DBMS_CLOUD_AI_AGENT.CREATE_TEAM(
    team_name => 'MED_RAG_TEAM',
    attributes => '{
      "agents": [
        {
          "name": "MED_RAG_AGENT",
          "task": "MED_SEARCH_TASK"
        }
      ],
      "process": "sequential"
    }',
    description => 'Team for med_history retrieval'
  );
END;
/


EXECUTE DBMS_CLOUD_AI_AGENT.CLEAR_TEAM;

EXECUTE DBMS_CLOUD_AI_AGENT.SET_TEAM('MED_RAG_TEAM');


-- 한글 지시어 반영한 결과


SET SERVEROUTPUT ON;

DECLARE
  l_result CLOB;
BEGIN
  l_result := DBMS_CLOUD_AI_AGENT.RUN_TEAM(
    team_name   => 'MED_RAG_TEAM',
    user_prompt => 'query 문진에서 두통을 호소하는 환자들을 찾아줘'
  );

  DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(l_result, 4000, 1));
END;
/

select ai agent 문진때 두통을 호소한 환자들을 찾아줘;

RESPONSE
--------------------------------------------------------------------------------
두통을 주요 증상으로 문진 받은 환자들의 의료 기록은 다음과 같습니다:

1. **이지은** (외래일자: 2023-10-10 12:15:00)
   - 문진내용: 두통과 구토
   - 진단병명: 급성 기관지염
   - 질문유사도: 1.0257844282766349E-001

2. **김지영** (외래일자: 2023-10-10 09:30:00)
   - 문진내용: 심한 두통과 어지러움
   - 진단병명: 급성 기관지염
   - 질문유사도: 1.0963298276477351E-001

3. **박현우** (외래일자: 2023-10-10 14:00:00)
   - 문진내용: 심한 두통과 구토
   - 진단병명: 머리 및 목의 심재성 2도 화상, 두피(모든부분)
   - 질문유사도: 1.1026289413239887E-001

4. **김영희** (외래일자: 2023-10-07 15:30:00)
   - 문진내용: 심한 두통과 구토
   - 진단병명: 급성 기관지염
   - 질문유사도: 1.1026289413239887E-001

select ai agent 의사의 처방 사유중에서 감기 또는 폐렴 가능성을 진단한 환자정보들을 찾아줘;

RESPONSE
--------------------------------------------------------------------------------

- 환자이름: 박민수, 외래일자: 2023-10-07 14:00:00
- 환자이름: 최영희, 외래일자: 2023-10-06 08:00:00
- 환자이름: 최지영, 외래일자: 2023-10-08 13:45:00 (여러 차례 방문 기록 있음)
- 환자이름: 이지은, 외래일자: 2023-10-09 09:30:00
- 환자이름: 박서연, 외래일자: 2023-10-09 09:30:00
- 환자이름: 박현우, 외래일자: 2023-10-06 13:45:00

이 환자들은 호흡곤란과 가슴 통증을 호소한 것으로 나타나며, 이 증상들은 폐렴 가능
성을 시사할 수 있습니다. 하지만 정확한 진단은 추가적인 검사와 정보가 필요합니다.


select ai agent 피부 보호 및 혈당 조절 문제로 입원한 환자들의 정보를 찾아줘;

RESPONSE
--------------------------------------------------------------------------------

- 환자이름: 박소영, 입원일시: 2023-10-08 11:00:00, 입원사유: 피부 상태 개선 및
당뇨병 관리, 담당의사이름: 홍지영, 진단병명: 피부 및 피하 조직의 합병증을 동반한
 성인발병 당뇨병(진성, 비비만성)
- 환자이름: 김대훈, 입원일시: 2023-10-08 11:00:00, 입원사유: 피부 상태 모니터링
및 당뇨병 관리, 담당의사이름: 이지은, 진단병명: 피부 및 피하 조직의 합병증을 동
반한 성인발병 당뇨병(진성, 비비만성)

select ai agent 병명이 급성 인두염 환자들의 정보를 찾아줘;
RESPONSE
--------------------------------------------------------------------------------
```json
[
    {"name": "김지혜", "date": "2023-06-15 10:00:00", "symptoms": "코가 막히고
콧물이 많이 납니다", "doctor": "최민수", "diagnosis": "급성 인두염", "similarity
": "1"},
    {"name": "황철수", "date": "2024-05-18 08:30:00", "symptoms": "코막힘과 콧물
", "doctor": "이지은", "diagnosis": "급성 인두염", "similarity": "1"},
    {"name": "김대훈", "date": "2023-05-12 11:00:00", "symptoms": "코막힘과 재채
기", "doctor": "이지은", "diagnosis": "급성 인두염", "similarity": "1"}
]

select ai agent 병명이 급성 인두염 환자들을 찾아줘;

급성 인두염으로 진단받은 환자들의 정보는 다음과 같습니다:

- 김지혜 (내원일: 2023-06-15)
- 황철수 (내원일: 2024-05-18)
- 김대훈 (내원일: 2023-05-12)
- 김민수 (내원일: 2023-08-12) - 주의: 이 환자는 급성 장염으로 진단되었으나, 질문
 유사도가 높아 포함되었습니다.
- 이영란 (내원일: 2023-08-12) - 주의: 이 환자는 급성 장염으로 진단되었으나, 질문
 유사도가 높아 포함되었습니다.
- 최영수 (내원일: 2023-10-20) - 주의: 이 환자는 급성 장염으로 진단되었으나, 질문
 유사도가 높아 포함되었습니다.


------------------------------------------------
confirmed 2026.0420 with exaone3.5