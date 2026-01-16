-- =================================================================
-- 0. EXTENSÕES (Necessário para gerar UUIDs)
-- =================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =================================================================
-- 1. LIMPEZA (Remove apenas o que será recriado)
-- =================================================================
DROP TABLE IF EXISTS ai_learning CASCADE;
DROP TABLE IF EXISTS workout_logs CASCADE;
DROP TABLE IF EXISTS workout_plans CASCADE;
DROP TABLE IF EXISTS user_preferences CASCADE;
-- DROP TABLE IF EXISTS workout_state; -- Removido pois não é usado no n8n
DROP TABLE IF EXISTS food_logs CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- =================================================================
-- 2. TABELAS ESSENCIAIS (Apenas as usadas no n8n)
-- =================================================================

-- 1. Usuários (Base para Foreign Keys)
CREATE TABLE users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    username TEXT UNIQUE NOT NULL, 
    current_weight DECIMAL(5,2),
    goal_weight DECIMAL(5,2),
    daily_calories_target INT DEFAULT 2000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Logs de Alimentação (Usado pelo nó "Create a row" - food_logs)
CREATE TABLE food_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE, 
    raw_text TEXT NOT NULL,       
    calories INT,                 
    protein DECIMAL(10,2),        
    carbs DECIMAL(10,2),          
    fat DECIMAL(10,2),            
    processed_json JSONB,         
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Preferências (Usado por "Get Preferences", "Code" e "Execute SQL Query")
-- Define o Estado Atual do Usuário (Objetivos, Lesões, Equipamentos)
CREATE TABLE user_preferences (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL PRIMARY KEY, 
    goal TEXT,                          
    injuries TEXT,                      
    disliked_exercises JSONB DEFAULT '[]'::JSONB, 
    disliked_foods JSONB DEFAULT '[]'::JSONB,     
    available_equipment JSONB DEFAULT '["Peso do corpo"]'::JSONB, 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- 4. Planos de Treino (Usado por "Get Workout Plan" e Agente Planner)
CREATE TABLE workout_plans (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL, 
    split_type TEXT,                
    current_day TEXT,               
    plan_structure JSONB,           -- O JSON do plano de 30 dias
    active BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- 5. Logs de Treino (Usado pelo nó "Create a row1" - workout_logs)
CREATE TABLE workout_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL, 
    workout_day TEXT,               
    exercises_performed JSONB,   
    calories_burned INT,          
    feedback TEXT,                  
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- 6. Aprendizado da IA (Usado por "Execute SQL query1" e "Get Learning")
-- Essencial para o Agente 4 (Feedback Loop)
CREATE TABLE ai_learning (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    topic TEXT DEFAULT 'Feedback Negativo', 
    bad_experience TEXT,                    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =================================================================
-- 3. DADOS DE TESTE (Seed para o n8n não quebrar no primeiro uso)
-- =================================================================

-- Cria os usuários que você usa nos testes CURL
INSERT INTO users (id, username, current_weight) 
VALUES 
('65239ade-c15e-4044-8f6e-423ea91809ae', 'usuario_teste_1', 80.0),
('fe1e80c2-34d1-4edb-a140-875c1c8cfa00', 'usuario_teste_2', 72.0)
ON CONFLICT (id) DO NOTHING;