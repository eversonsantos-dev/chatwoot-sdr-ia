class AddClosingMessagesToSdrIaConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :sdr_ia_configs, :closing_messages, :jsonb, default: {
      'quente' => "Perfeito! Vejo que você tem grande interesse 🎯\nVou te conectar AGORA com {{agent_name}}, nossa especialista. Ela vai te ajudar a agendar sua avaliação! 😊",
      'morno' => "Ótimo! Entendi suas necessidades 😊\nVou te enviar nosso portfólio com resultados reais e tabela de valores.\n{{agent_name}} vai entrar em contato em até 2 horas para tirar suas dúvidas. Tudo bem?",
      'frio' => "Entendi que você está no início da pesquisa! 💙\nVou te adicionar em nosso grupo de conteúdos e promoções.\nQuando quiser conversar mais, é só chamar!",
      'muito_frio' => "Obrigado pelo contato! 😊\nSe mudar de ideia, estarei por aqui!"
    }
  end
end
