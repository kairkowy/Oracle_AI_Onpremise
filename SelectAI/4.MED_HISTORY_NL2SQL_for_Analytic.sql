-- med_history 테이블 정보
desc med_history
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
 DGNSS_HNGNM_V                                      VECTOR(*, *, DENSE)
 SYMPT_PTT_V                                        VECTOR(*, *, DENSE)
 PCR_REASON_V                                       VECTOR(*, *, DENSE)
 IP_REASON_V                                        VECTOR(*, *, DENSE)


-- 날짜 가상 컬럼 추가
ALTER TABLE med_history 
ADD (
  visit_dttm_virtual DATE
    GENERATED ALWAYS AS (TO_DATE(visit_dttm, 'YYYY-MM-DD HH24:MI:SS')) VIRTUAL,
  ip_dttm_virtual DATE
    GENERATED ALWAYS AS (TO_DATE(ip_dttm, 'YYYY-MM-DD HH24:MI:SS')) VIRTUAL,
  DCH_DTTM_virtual DATE
  GENERATED ALWAYS AS (TO_DATE(DCH_DTTM, 'YYYY-MM-DD HH24:MI:SS')) VIRTUAL
);

---------------------------------------
-- 분석 정보를 위한 뷰 생성
-- Var2Datatime 전환
---------------------------------------

CREATE OR REPLACE VIEW MED_HISTORY_NL2SQL AS
SELECT
 PTT_NAME,           
 VISIT_DTTM_VIRTUAL, 
 DGNSS_HNGNM,  
 DR_NAME,    
 TREAT_CLASS,  
 IP_DTTM_VIRTUAL,     
 DCH_DTTM_VIRTUAL
FROM MED_HISTORY;


------------------------------------------------------
-- MED_HISTORY_NL2SQL comments & annotations 추가
-------------------------------------------------------
comment on table MED_HISTORY_NL2SQL is '병원 기록 분석 쿼리를 위한 view';
COMMENT ON COLUMN MED_HISTORY_NL2SQL.PTT_NAME IS '환자이름, 환자명, 환자';
COMMENT ON COLUMN MED_HISTORY_NL2SQL.visit_dttm_virtual IS '환자가 병원에 방문한 일시(TIMESTAMP 형식)';
COMMENT ON COLUMN MED_HISTORY_NL2SQL.ip_dttm_virtual IS '입원 일시, 환자가 병실에 입원한 일시(TIMESTAMP 형식)';
COMMENT ON COLUMN MED_HISTORY_NL2SQL.DCH_DTTM_virtual IS '퇴원 일시, 환자가 병원에서 퇴원한 일시(TIMESTAMP 형식)';
COMMENT ON COLUMN MED_HISTORY_NL2SQL.treat_class IS '진료 구분 코드. 값은 "외래" 또는 "입원"';
COMMENT ON COLUMN MED_HISTORY_NL2SQL.dr_name IS '의사 이름';
COMMENT ON COLUMN MED_HISTORY_NL2SQL.DGNSS_HNGNM IS '환자의 병명';


-----------------------------------------
-- NL2SQL 프로파일 생성
-- gemma2:9b 가 추론이 좋음
-----------------------------------------
BEGIN
  -- 있으면 삭제 (force => true)
  DBMS_CLOUD_AI.DROP_PROFILE(
    profile_name => 'SELECTAI_MED',
    force        => TRUE
  );
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  DBMS_CLOUD_AI.CREATE_PROFILE(
    profile_name => 'SELECTAI_MED',
    attributes   => '{
      "provider":"OPENAI",
      "provider_endpoint": "http://service-ollama",
      "model": "gemma2:9b",
      "conversation": false,
      "max_tokens": 4096,
      "temperature": 0,
      "annotations": true,
      "seed": 42,
      "comments": true,
      "object_list": [
        {"owner": "LABADMIN", "name": "MED_HISTORY_NL2SQL"}
      ]
    }',
    status       => 'enabled',
    description  => 'Select AI profile for Med History'
  );
END;
/

--------------------------------------------
-- SELECT AI(NL2SQL) 실행
--------------------------------------------
execute DBMS_CLOUD_AI.set_profile('SELECTAI_MED');

select ai runsql 년도별로 입원 환자를 집계해줘?;

  입원년도 입원환자수
---------- ----------
      2023        570


select ai runsql 년도별 외래 환자수는?;


      년도 외래 환자 수
---------- ------------
      2023          428



-------------------------------