import { Heading, Button } from "@medusajs/ui"
import LocalizedClientLink from "@modules/common/components/localized-client-link"

const Hero = () => {
  return (
    <div className="relative h-[75vh] w-full border-b border-ui-border-base overflow-hidden">
      {/* Background com gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-primary/10 via-background to-accent/10">
        {/* Círculos decorativos */}
        <div className="absolute top-0 -left-4 w-72 h-72 bg-primary/20 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob"></div>
        <div className="absolute top-0 -right-4 w-72 h-72 bg-accent/20 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-2000"></div>
        <div className="absolute -bottom-8 left-20 w-72 h-72 bg-secondary/20 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-4000"></div>
      </div>

      {/* Conteúdo */}
      <div className="absolute inset-0 z-10 flex flex-col justify-center items-center text-center px-6 small:px-32 gap-8">
        <div className="space-y-6">
          <Heading
            level="h1"
            className="text-5xl small:text-7xl leading-tight text-ui-fg-base font-bold drop-shadow-sm"
          >
            Bem-vindo à JF Imperadores
          </Heading>
          <Heading
            level="h2"
            className="text-xl small:text-3xl leading-relaxed text-ui-fg-subtle font-normal max-w-3xl mx-auto"
          >
            Descubra produtos incríveis com os melhores preços e ofertas exclusivas
          </Heading>
        </div>
        
        <div className="flex gap-4 flex-wrap justify-center">
          <LocalizedClientLink href="/store">
            <Button size="large" className="shadow-lg hover:shadow-xl transition-shadow">
              Ver Produtos
            </Button>
          </LocalizedClientLink>
          <LocalizedClientLink href="/collections">
            <Button size="large" variant="secondary" className="shadow-lg hover:shadow-xl transition-shadow">
              Ver Coleções
            </Button>
          </LocalizedClientLink>
        </div>

        {/* Indicador de scroll */}
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 animate-bounce">
          <svg className="w-6 h-6 text-ui-fg-subtle" fill="none" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" viewBox="0 0 24 24" stroke="currentColor">
            <path d="M19 14l-7 7m0 0l-7-7m7 7V3"></path>
          </svg>
        </div>
      </div>
    </div>
  )
}

export default Hero
