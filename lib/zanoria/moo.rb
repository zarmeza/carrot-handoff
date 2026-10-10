# frozen_string_literal: true

module Zanoria
  # The easter egg.
  #
  # The name is a joke from San Rafael de Mucuchíes: a campesino drops a carrot,
  # which by local superstition means somebody is thinking of him, and the
  # mishearing — *zanahoria* read as *sanoria*, Cecilia spelled *sesilia* — is
  # the clue he reasons from rather than a typo. So the art shows the drop and
  # leaves the consequence out. Spelling out the punchline would hand the joke to
  # the people who could not have got there, and flatten it for everyone else.
  #
  # Nothing here reads or writes anything. No note, no git, no repository state:
  # a command run to be amused should not leave a mark on the tree it ran in.
  # That is also why it is absent from `USAGE` — an easter egg listed in the
  # command table is a feature, and this is not one. The spec pins both
  # properties, because neither survives a well-meaning tidy-up on its own.
  module Moo
    # Quoted heredoc, `<<~'ART'`, and the quoting is load-bearing. In an
    # interpolating heredoc `\ ` is an escape sequence, so the peasant arrives
    # without arms and without a carrot, and the only symptom is a drawing that
    # is subtly wrong in a way no assertion about *content* would ever catch.
    # `ART.gsub('\\', '/')` renders identically to this and is worse.
    ART = <<~'ART'
      Se me cayó la zanoria :]      .------.
            ___                     ( moo  )
           /   \                     '------'
          |_____|                       ___
           |   |                       ( o o )
           |   |___                   (  ^  )
           |    __|                    \___/
           |   |  |
            \  |  /
             \ | /
              \|/

                    v
                   /\
                  /  \
                  \  /
                   \/
    ART

    module_function

    def render
      ART
    end
  end
end
