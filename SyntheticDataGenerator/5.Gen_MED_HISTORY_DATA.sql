---------------------------------------
-- 오라클 SDG 기능을 이용한 가상의 병원 정보 생성
--------------------------------------
-- Table 생성

```sql
create table med_history
(ptt_name  varchar(10),
visit_dttm  varchar(20),
sympt_ptt varchar2(1000),
DGNSS_HNGNM  varchar(100),
dr_name varchar(10),
pcr_reason varchar2(1000),
treat_class varchar(6),  
ip_dttm     varchar(20),
ip_reason varchar2(1000),
DCH_DTTM  varchar(20)
);
```
----------------------------------
-- SDG용 프로파일 생성
---------------------------------
set serverout on

BEGIN
  -- 있으면 삭제 (force => true)
  DBMS_CLOUD_AI.DROP_PROFILE(
    profile_name => 'SELECTAI_SDG',
    force        => TRUE
  );
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  -- 생성
  DBMS_CLOUD_AI.CREATE_PROFILE(
    profile_name => 'SELECTAI_SDG',
    attributes   => '{
      "provider":"OPENAI",
      "provider_endpoint": "http://service-ollama",
      "model": "exaone3.5"
      }',
    status       => 'enabled',
    description  => 'Select AI profile for Synthetic Data Generation'
  );
END;
/

-------------------------------------------
-- SDG 이용한 데이터 생성
-------------------------------------------
BEGIN
  DBMS_CLOUD_AI.GENERATE_SYNTHETIC_DATA(
    profile_name => 'SELECTAI_SDG',
    object_name  => 'med_history',
    owner_name   => 'LABADMIN',
    record_count => 500,
    user_prompt  => '
다음 컬럼 구조를 가지는 의료 데이터 테이블 MED_HISTORY에 대해 현실적인 한국 병원 데이터를 생성하라.

[컬럼 정의]
- ptt_name: 환자이름 (한글 이름)
- visit_dttm: 내원일시 (YYYY-MM-DD HH24:MI:SS 형식)
- sympt_ptt: 문진 내용 (환자가 말하는 자연스러운 증상 표현)
- pcr_reason: 의사소견 (증상 + 진찰 기반 의학적 판단, 전문적인 문장)
- dr_name: 의사이름 (한글 이름)
- treat_class: 진료구분 ("외래" 또는 "입원")
- ip_dttm: 입원일시 (YYYY-MM-DD HH24:MI:SS 형식, 입원인 경우만 값 생성, 아니면 NULL)
- ip_reason: 입원사유 (입원인 경우만 작성, 의사 소견 기반)
- DGNSS_HNGNM: 병명 (아래 목록 중 하나 선택)
- DCH_DTTM: 퇴원일시 (YYYY-MM-DD HH24:MI:SS 형식, 입원인 경우만 생성)

[병명 목록]
머리 및 목의 심재성 2도 화상, 입술
머리 및 목의 심재성 2도 화상, 턱
머리 및 목의 심재성 2도 화상, 코(중격)
머리 및 목의 심재성 2도 화상, 두피(모든부분)
머리 및 목의 심재성 2도 화상, 이마와 볼
마크로알부민뇨를 동반한 영양실조-관련 당뇨병(N08.3*)
사구체경화증(미만성)(모세혈관내)(결절성)을 동반한 영양실조-관련 당뇨병(N08.3*)
신장질환(진행된)(NOS)(진행형)을 동반한 영양실조-관련 당뇨병(N08.3*)
만성 콩팥병을 동반한 영양실조-관련 당뇨병(N08.3*)
만성 신부전증 동반한 영양실조-관련 당뇨병(N08.3*)
피부 및 피하 조직의 합병증을 동반한 성인발병 당뇨병(진성, 비비만성)
급성 비인두염 (Common cold)
급성 상기도감염
급성 인두염
급성 편도염
급성 기관지염

[생성 규칙]
1. sympt_ptt는 환자가 실제 말하는 자연스러운 한국어 문장으로 작성
2. pcr_reason은 의사의 진단 소견으로 의학적 용어를 사용하여 작성
3. dr_name, ptt_name은 한국인 이름으로 생성
4. treat_class가 "입원"인 경우:
   - ip_dttm는 visit_dttm 이후로 생성
   - DCH_DTTM은 ip_dttm 이후로 생성
   - ip_reason은 구체적인 입원 사유 작성
5. treat_class가 "외래"인 경우:
   - ip_dttm, ip_reason, DCH_DTTM은 반드시 NULL
6. 날짜 정합성:
   - visit_dttm < ip_dttm < DCH_DTTM (입원인 경우)
7. sympt_ptt와 pcr_reason은 DGNSS_HNGNM과 임상적으로 일관되게 생성
8. 데이터 비율:
   - visit_dttm은 2023년, 2024년, 2025년를 월별로 임의로 배분
   - 화상: 50% 이상 입원
   - 당뇨 합병증: 20% 이상 입원
9. 전체 데이터는 병명 목록을 참고해서 현실적인 의료 데이터처럼 다양하게 생성
'
  );
END;
/

-----------------------------------
-- 데이터 확인
------------------------------------

col 환자명 format a20
col 외래일시 format a20
col 증상 format a40
col 진단명 format a70
col 의사명 format a20
col 진단사유 format a70
col 치료구분 format a8
col 입원일 format a20
col 입원사유 format a60
col 퇴원일시 format a20

select ptt_name 환자명, dr_name 의사명, treat_class 치료구분, visit_dttm 외래일시, sympt_ptt 증상, DGNSS_HNGNM 진단명, pcr_reason 진단사유, ip_dttm 입원일, ip_reason 입원사유 , dch_dttm 퇴원일시 from med_history
fetch first 10 rows only;

환자명               의사명               치료구분 외래일시             증상                                     진단명
-------------------- -------------------- -------- -------------------- ---------------------------------------- ----------------------------------------------------------------------
진단사유                                                               입원일               입원사유                                                     퇴원일시
---------------------------------------------------------------------- -------------------- ------------------------------------------------------------ --------------------
최지영               박영호               외래     2024-04-05 11:00:00  두통과 구토 증상                         마크로알부민뇨를 동반한 영양실조-관련 당뇨병(N08.3*)
영양실조와 당뇨병 복합 증상 확인

김미영               이지은               외래     2023-08-12 10:00:00  심한 두통과 시력 저하                    급성 기관지염
호흡기 감염 증상 확인

이영희               최민수               외래     2023-02-20 09:45:00  기침과 콧물이 지속된다                   급성 비인두염 (Common cold)
급성 비인두염 진단, 증상 관리 필요

이영희               최민수               외래     2023-02-20 09:45:00  기침과 콧물이 지속된다                   급성 비인두염 (Common cold)
급성 비인두염 진단, 증상 관리 필요

박민수               최영희               외래     2025-10-15 15:00:00  입술 주변에 통증과 붓기                  머리 및 목의 심재성 2도 화상, 턱
화상 부위 확인 및 치료 필요

최수현               황지영               외래     2023-07-03 16:45:00  지속적인 기침과 가래                     급성 기관지염
급성 기관지염 진단, 항생제 처방

이영희               최민수               외래     2023-02-20 09:45:00  기침과 콧물이 지속된다                   급성 비인두염 (Common cold)
급성 비인두염 진단, 증상 관리 필요

황진아               이지은               외래     2024-05-18 08:45:00  지속적인 피로감과 식욕 부진              마크로알부민뇨를 동반한 영양실조-관련 당뇨병(N08.3*)
영양 상태 개선 및 당뇨병 관리 필요

김민수               이지은               외래     2023-08-12 09:30:00  지속적인 복통과 설사                     급성 장염
장염 진단, 수액 치료 및 항생제 처방 필요

황진아               이지은               외래     2024-05-18 08:45:00  지속적인 복통과 설사                     마크로알부민뇨를 동반한 영양실조-관련 당뇨병(N08.3*)
영양실조와 당뇨병 복합 증상 확인, 영양 상태 개선 및 혈당 관리 필요



SQL> select count(*) from med_history;

  COUNT(*)
----------
       480

SQL> select treat_class, count(*) from med_history group by treat_class;

TREAT_CLASS          COUNT(*)
------------------ ----------
입원                      248
외래                      232


SQL> select substr(visit_dttm, 1,4) YEAR, count(*) from med_history group by YEAR

YEAR                                               COUNT(*)
------------------------------------------------ ----------
2024                                                    132
2025                                                     66
2023                                                    282


SQL> select distinct(DGNSS_HNGNM) 진단명 from med_history

진단명
--------------------------------------------------------------------------------
마크로알부민뇨를 동반한 영양실조-관련 당뇨병(N08.3*)
급성 기관지염
머리 및 목의 심재성 2도 화상, 턱
신장질환(진행된)(NOS)(진행형)을 동반한 영양실조-관련 당뇨병(N08.3*)
급성 뇌졸중 (가정된 진단)
머리 및 목의 심재성 2도 화상, 입술
급성 비인두염 (Common cold)
만성 콩팥병을 동반한 영양실조-관련 당뇨병(N08.3*)
급성 상기도감염
만성 신부전증 동반한 영양실조-관련 당뇨병(N08.3*)
피부 및 피하 조직의 합병증을 동반한 성인발병 당뇨병(진성, 비비만성)
머리 및 목의 심재성 2도 화상, 코(중격)
머리 및 목의 심재성 2도 화상, 두피(모든부분)
급성 뇌막염 (NOS)
급성 인두염
사구체경화증(미만성)(모세혈관내)(결절성)을 동반한 영양실조-관련 당뇨병
급성 장염
뇌졸중
급성 복통 증후군
피부 및 피하 조직의 합병증을 동반한 성인발병 당뇨병
급성 뇌막염
머리 및 목의 심재성 2도 화상, 이마와 볼
심장 질환(진행된)(NOS)(진행형)


