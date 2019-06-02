CREATE OR REPLACE TRIGGER Шифр_Специальности_Trg
FOR INSERT OR UPDATE OF Название_Специальности ON Специальности
COMPOUND TRIGGER

  FUNCTION getCipher (specName Специальности.Название_Специальности%TYPE)
  RETURN Специальности.Шифр_Специальности%TYPE IS
    word_re VARCHAR2(256)  := '[[:alpha:]]([-''_[:alpha:][:digit:]]*[''[:alpha:][:digit:]])?';
    letters VARCHAR2(1024) := '';
    word VARCHAR2(1024);
  BEGIN 
    IF specName IS NULL THEN RETURN NULL; END IF;
    FOR i IN 1..REGEXP_COUNT(specName, word_re) LOOP
      word    := REGEXP_SUBSTR(specName, word_re, 1, i);
      letters := letters || REGEXP_SUBSTR(word, '[[:alpha:]]', 1, 1);
    END LOOP;
    RETURN letters;
  END;

  BEFORE EACH ROW IS
  BEGIN
    -- Меняем Шифр_Специальности только если фактические значения
    -- столбцов Название_Специальности различаются
    IF UPDATING AND NOT (
      :OLD.Название_Специальности IS NULL AND :NEW.Название_Специальности IS NULL
    ) AND (
         :OLD.Название_Специальности IS NULL OR :NEW.Название_Специальности IS NULL
      OR :OLD.Название_Специальности != :NEW.Название_Специальности
    )
    THEN
      :NEW.Шифр_Специальности := getCipher(:NEW.Название_Специальности);
    END IF;
    IF INSERTING THEN
      :NEW.Шифр_Специальности := getCipher(:NEW.Название_Специальности);
    END IF;
  END BEFORE EACH ROW;

END Шифр_Специальности_Trg;
/