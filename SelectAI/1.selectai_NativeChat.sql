---------------------------------------
-- SELECTAI_CHAT profile 생성
--------------------------------------
set serverout on

BEGIN
  -- 있으면 삭제 (force => true)
  DBMS_CLOUD_AI.DROP_PROFILE(
    profile_name => 'SELECTAI_CHAT',
    force        => TRUE
  );
END;
/

BEGIN
  -- 생성
  DBMS_CLOUD_AI.CREATE_PROFILE(
    profile_name => 'SELECTAI_CHAT',
    attributes   => '{
      "provider":"OPENAI",
      "provider_endpoint": "http://service-ollama",
      "model": "exaone3.5",
      "conversation": false,
      "max_tokens": 1024,
      "temperature": 0,
      "annotations": true,
      "seed": 42
      }',
    status       => 'enabled',
    description  => 'Select AI profile for private Ollama via Nginx proxy'
  );
END;
/

EXECUTE DBMS_CLOUD_AI.SET_PROFILE('SELECTAI_CHAT');

prompt "SELECT AI CHAT '자연어질문'을 실행하세요"
